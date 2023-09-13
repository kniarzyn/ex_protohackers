defmodule ExProtohackers.BudgetChatServer do
  use GenServer

  require Logger

  @port 5004

  defstruct [:listen_socket, :supervisor, :ets]

  def start_link(opts = []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    {:ok, supervisor} = Task.Supervisor.start_link()
    ets = :ets.new(__MODULE__, [:public])

    socket_options = [
      mode: :binary,
      active: false,
      packet: :line,
      reuseaddr: true,
      exit_on_close: false
    ]

    case :gen_tcp.listen(@port, socket_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting BudgetChat Server on port #{@port}")

        state = %__MODULE__{
          listen_socket: listen_socket,
          supervisor: supervisor,
          ets: ets
        }

        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn ->
          handle_connection(socket, state.ets)
        end)

        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        Logger.debug("Error during accepting connection: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  ## Private

  defp handle_connection(socket, ets) do
    :gen_tcp.send(socket, "Welcome to budget chat! What shall I call you?\n")

    with {:ok, username} <- :gen_tcp.recv(socket, 0, 180_000),
         {:ok, username} <- validate_username(username),
         {users, sockets} <- :ets.tab2list(ets) |> Enum.unzip(),
         true <- :ets.insert(ets, {username, socket}) do
      :gen_tcp.send(socket, "* The room contains: #{Enum.join(users, ", ")}\n")

      for user_socket <- sockets do
        :gen_tcp.send(user_socket, "* #{username} has entered the room.\n")
      end

      handle_chat_session(socket, ets, username)
    else
      {:error, :illegal_username, username} ->
        Logger.debug("Illegal username: #{inspect(username)}")
        :gen_tcp.send(socket, "Illegal username! Choose another one.")

      msg ->
        Logger.debug("#{inspect(msg)}")
    end
  end

  defp handle_chat_session(socket, ets, username) do
  end

  defp validate_username(username) do
    username = String.trim(username)

    case username =~ ~r/^[[:alnum:]]+$/ do
      true ->
        {:ok, username}

      _ ->
        {:error, :illegal_username, username}
    end
  end
end
