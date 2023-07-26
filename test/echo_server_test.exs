defmodule ExProtohackers.EchoServerTest do
  use ExUnit.Case, async: true

  require Logger

  test "echoes everything back" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
    assert :gen_tcp.send(socket, "Code") == :ok
    assert :gen_tcp.send(socket, "Clean") == :ok

    # close write side of the socket
    :gen_tcp.shutdown(socket, :write)

    assert :gen_tcp.recv(socket, 0) == {:ok, "CleanCode"}
  end

  # or @tag :capture_log
  test "protect form buffer overflow (100Kb)" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)

    assert ExUnit.CaptureLog.capture_log(fn ->
             assert :ok == :gen_tcp.send(socket, :binary.copy("a", 100 * 1024 + 1))
             assert {:error, :closed} == :gen_tcp.recv(socket, 0)
           end) =~ ":buffer_overflow"
  end
end
