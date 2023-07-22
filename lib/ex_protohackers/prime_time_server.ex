defmodule ExProtohackers.PrimeTimeServer do
  use GenServer

  require Logger

  @prime_time_port 5002

  defstruct [:listen_socket, :supervisor]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_opts) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 5)

    listen_socket_options = [
      active: false,
      exit_on_close: false,
      mode: :binary,
      packet: :line,
      reuseaddr: true
    ]

    case :gen_tcp.listen(@prime_time_port, listen_socket_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting Prime Time Server on port #{@prime_time_port}")
        state = %__MODULE__{listen_socket: listen_socket, supervisor: supervisor}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    {:noreply, state, {:continue, :accept}}
  end
end
