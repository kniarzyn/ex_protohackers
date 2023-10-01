defmodule ExProtohackers.BudgetChatServerTest do
  use ExUnit.Case

  test "ask and register username for connection" do
    {:ok, socket1} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    {:ok, socket2} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    {:ok, socket3} =
      :gen_tcp.connect(~c"localhost", 5004, mode: :binary, active: false, packet: :line)

    assert {:ok, "Welcome to budget chat! What shall I call you?\n"} = :gen_tcp.recv(socket1, 0)
    :ok = :gen_tcp.send(socket1, "Tom\n")
    assert {:ok, "* The room contains: \n"} = :gen_tcp.recv(socket1, 0)

    assert {:ok, "Welcome to budget chat! What shall I call you?\n"} =
             :gen_tcp.recv(socket2, 0, 1_000)

    :ok = :gen_tcp.send(socket2, "John\n")
    assert {:ok, "* The room contains: Tom\n"} = :gen_tcp.recv(socket2, 0, 1_000)

    assert {:ok, "Welcome to budget chat! What shall I call you?\n"} =
             :gen_tcp.recv(socket3, 0, 1_000)

    :ok = :gen_tcp.send(socket3, "Benedict\n")
    assert {:ok, "* The room contains: John, Tom\n"} = :gen_tcp.recv(socket3, 0, 1_000)
  end
end
