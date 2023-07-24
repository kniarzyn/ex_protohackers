defmodule ExProtohackers.PrimeTimeServer do
  use GenServer

  require Logger

  @buffer_size 100 * 1024
  @server_port 5002

  defstruct [:listen_socket, :supervisor]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_opts) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 5)

    listen_socket_options = [
      active: false,
      buffer: @buffer_size,
      exit_on_close: false,
      mode: :binary,
      packet: :line,
      reuseaddr: true
    ]

    case :gen_tcp.listen(@server_port, listen_socket_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting Prime Time Server on port #{@server_port}")
        state = %__MODULE__{listen_socket: listen_socket, supervisor: supervisor}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn -> handle_connection(socket) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  ## Helpers
  defp handle_connection(socket) do
    case readline(socket) do
      {:ok, :closed} ->
        :ok

      {:error, reason} ->
        Logger.debug("Error during reading: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp readline(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        data
        |> prepare_response()
        |> send_response(socket)

        readline(socket)

      {:error, :closed} ->
        {:ok, :closed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prepare_response(data) do
    data
    |> Jason.decode()
    |> case do
      {:ok, %{"method" => "isPrime", "number" => number} = _request} ->
        %{method: "isPrime", prime: is_prime?(number)}

      other ->
        Logger.debug("Malformed request: #{inspect(other)}")
        "malformed request"
    end
    |> Jason.encode!()
    |> Kernel.<>("\n")
  end

  defp send_response(response, socket) do
    :gen_tcp.send(socket, response)
  end

  defp is_prime?(number) when is_float(number), do: false
  defp is_prime?(number) when number <= 1, do: false
  defp is_prime?(number) when number in [2, 3], do: true

  defp is_prime?(number) do
    not Enum.any?(2..trunc(:math.sqrt(number)), fn divider -> rem(number, divider) == 0 end)
  end
end
