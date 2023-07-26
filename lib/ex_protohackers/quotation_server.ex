defmodule ExProtohackers.QuotationServer do
  use GenServer

  require Logger

  alias ExProtohackers.QuotationServer.DB

  @port 5003

  defstruct [:listen_socket, :supervisor]

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 20)

    socket_options = [
      mode: :binary,
      active: false,
      reuseaddr: true
    ]

    case :gen_tcp.listen(@port, socket_options) do
      {:ok, socket} ->
        Logger.info("Starting Quotation Server on port: #{@port}")
        state = %__MODULE__{listen_socket: socket, supervisor: supervisor}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        Logger.debug("Server shutdown: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn ->
          handle_connection(socket)
        end)

        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        Logger.debug("Error while accepting conection: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  # Helpers 
  defp handle_connection(socket) do
    Logger.debug("Starting session...")
    handle_requests(socket, DB.new())

    Logger.debug("Closing session.")
    :gen_tcp.close(socket)
  end

  defp handle_requests(socket, db) do
    case :gen_tcp.recv(socket, 9, 10_000) do
      {:ok, request} ->
        case handle_request(request, db) do
          {:error, reason} ->
            Logger.debug("Error while handling request: #{inspect(reason)}")

          {db, nil} ->
            handle_requests(socket, db)

          {db, response} ->
            :gen_tcp.send(socket, response)
            handle_requests(socket, db)
        end

      {:error, :timeout} ->
        handle_requests(socket, db)

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        Logger.debug("Error while handling connection: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp handle_request(<<?I, time::32-signed-big, price::32-signed-big>>, db) do
    db = DB.insert(db, time, price)
    {db, nil}
  end

  defp handle_request(<<?Q, mintime::32-signed-big, maxtime::32-signed-big>>, db) do
    mean_price = DB.query(db, mintime, maxtime)
    {db, <<mean_price::32-signed-big>>}
  end

  defp handle_request(_request, _db) do
    {:error, :malformed_request}
  end
end
