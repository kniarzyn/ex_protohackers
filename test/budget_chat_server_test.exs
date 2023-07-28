defmodule ExProtohackers.BudgetChatServerTest do
  use ExUnit.Case

  setup do
    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    {:ok, socket: socket}
  end

  test "ask for name on connection", %{socket: socket} do
    assert {:ok, "Welcome to budget chat! What shall I call you?\n"} = :gen_tcp.recv(socket, 0)
  end
end
