defmodule ExProtohackers.EchoServerTest do
  use ExUnit.Case

  test "echoes everything back" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
    assert :gen_tcp.send(socket, "Clean") == :ok
    assert :gen_tcp.send(socket, "Code") == :ok

    # close write side of the socket
    :gen_tcp.shutdown(socket, :write)

    assert :gen_tcp.recv(socket, 0) == {:ok, "CleanCode"}
  end

  test "protect form buffer overflow (100Kb)" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
    assert :gen_tcp.send(socket, :binary.copy("a", 100 * 1024 + 1)) == :ok

    assert :gen_tcp.recv(socket, 0) == {:error, :closed}
  end
end
