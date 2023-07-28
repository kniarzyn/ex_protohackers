defmodule ExProtohackers.BudgetChatServer do
  use GenServer

  require Logger

  @port 5004

  defstruct [:listen_socket]

  def start_link(opts = []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    socket_options = [
      mode: :binary,
      active: false,
      packet: :line
    ]

    case :gen_tcp.listen(@port, socket_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting BudgetChat Server on port #{@port}")
        {:ok, %__MODULE__{listen_socket: listen_socket}, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        :gen_tcp.send(socket, "Welcome to budget chat! What shall I call you?\n")

      {:error, reason} ->
        Logger.debug("Error during accepting connection: #{inspect(reason)}")
        {:noreply, state, {:continue, :accept}}
    end

    {:noreply, state}
  end
end
