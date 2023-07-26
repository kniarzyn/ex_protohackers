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
end
