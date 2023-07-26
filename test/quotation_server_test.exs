defmodule ExProtohackers.QuotationServerTest do
  use ExUnit.Case

  require Logger

  test "Quotation Server" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5003, mode: :binary, active: false)

    :ok = :gen_tcp.send(socket, <<?I, 1::32-signed-big, 100::32-signed-big>>)
    :ok = :gen_tcp.send(socket, <<?I, 2::32-signed-big, 300::32-signed-big>>)
    :ok = :gen_tcp.send(socket, <<?I, 3::32-signed-big, 200::32-signed-big>>)
    :ok = :gen_tcp.send(socket, <<?I, 4::32-signed-big, 500::32-signed-big>>)

    :ok = :gen_tcp.send(socket, <<?Q, 2::32-signed-big, 4::32-signed-big>>)
    assert {:ok, <<333::size(32)>>} = :gen_tcp.recv(socket, 4, 1_000)
  end

  test "separate DB for each session/connection" do
    {:ok, socket1} = :gen_tcp.connect(~c"localhost", 5003, mode: :binary, active: false)
    {:ok, socket2} = :gen_tcp.connect(~c"localhost", 5003, mode: :binary, active: false)

    # connection 1 
    :ok = :gen_tcp.send(socket1, <<?I, 1::32-signed-big, 100::32-signed-big>>)
    :ok = :gen_tcp.send(socket1, <<?I, 2::32-signed-big, 300::32-signed-big>>)
    :ok = :gen_tcp.send(socket1, <<?I, 3::32-signed-big, 200::32-signed-big>>)
    :ok = :gen_tcp.send(socket1, <<?I, 4::32-signed-big, 500::32-signed-big>>)
    #
    # connection 2 
    :ok = :gen_tcp.send(socket2, <<?I, 1::32-signed-big, 10::32-signed-big>>)
    :ok = :gen_tcp.send(socket2, <<?I, 2::32-signed-big, 30::32-signed-big>>)
    :ok = :gen_tcp.send(socket2, <<?I, 3::32-signed-big, 20::32-signed-big>>)
    :ok = :gen_tcp.send(socket2, <<?I, 4::32-signed-big, 50::32-signed-big>>)

    :ok = :gen_tcp.send(socket1, <<?Q, 1::32-signed-big, 3::32-signed-big>>)
    assert {:ok, <<200::size(32)>>} = :gen_tcp.recv(socket1, 4, 1_000)
    :ok = :gen_tcp.send(socket2, <<?Q, 1::32-signed-big, 3::32-signed-big>>)
    assert {:ok, <<20::size(32)>>} = :gen_tcp.recv(socket2, 4, 1_000)
  end
end
