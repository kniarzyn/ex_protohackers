defmodule ExProtohackers.EchoServer do
  use GenServer

  require Logger

  defstruct [:listen_socket]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  @impl true
  def init(:no_state) do
    listen_options = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false
    ]

    case :gen_tcp.listen(5001, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting EchoServer on port: 5001")
        state = %__MODULE__{listen_socket: listen_socket}

        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        handle_connection(socket)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp handle_connection(socket) do
    case read_until_closed(socket, _buffer = "") do
      {:ok, data} -> :gen_tcp.send(socket, data)
      {:error, reason} -> Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp read_until_closed(socket, buffer) do
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, data} -> read_until_closed(socket, [buffer, data])
      {:error, :closed} -> {:ok, buffer}
      {:error, reason} -> {:error, reason}
    end
  end
end
