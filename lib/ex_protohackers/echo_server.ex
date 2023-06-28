defmodule ExProtohackers.EchoServer do
  use GenServer

  require Logger

  defstruct [:listen_socket]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  @impl true
  def init(:no_state) do
    listen_socket_options = [
      mode: :binary
    ]

    case :gen_tcp.listen(5001, listen_socket_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting EchoServer on port: 5001")
        state = %__MODULE__{listen_socket: listen_socket}

        {:ok, {:continue, state}}

      {:error, reason} ->
        {:stop, reason}
    end
  end
end
