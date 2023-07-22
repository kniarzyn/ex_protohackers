defmodule ExProtohackers.EchoServer do
  use GenServer

  require Logger

  defstruct [:listen_socket, :supervisor]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  @impl true
  def init(:no_state) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 5)

    listen_options = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false
    ]

    case :gen_tcp.listen(5001, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting EchoServer on port: 5001")
        state = %__MODULE__{listen_socket: listen_socket, supervisor: supervisor}

        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn -> handle_connection(socket) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp handle_connection(socket) do
    case read_until_closed(socket, _buffer = "", _byte_size = 0) do
      {:ok, data} -> :gen_tcp.send(socket, data)
      {:error, reason} -> Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  @buffer_limit _100_Kb = 1024 * 100
  defp read_until_closed(socket, buffer, buffer_size) do
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, data} when buffer_size + byte_size(data) > @buffer_limit ->
        {:error, :buffer_overflow}

      {:ok, data} ->
        read_until_closed(socket, [buffer, data], buffer_size + byte_size(data))

      {:error, :closed} ->
        {:ok, buffer}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
