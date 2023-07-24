defmodule PrimeTimeServerTest do
  use ExUnit.Case

  test "response to valid request when number is not prime number" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5002, mode: :binary, active: false)
    assert :ok = :gen_tcp.send(socket, ~c"{\"method\":\"isPrime\",\"number\":123}\n")
    {:ok, data} = :gen_tcp.recv(socket, 0)
    assert data == "{\"method\":\"isPrime\",\"prime\":false}\n"
  end

  test "response to valid request when number is prime number" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5002, mode: :binary, active: false)
    assert :ok = :gen_tcp.send(socket, ~c"{\"method\":\"isPrime\",\"number\":11}\n")
    {:ok, data} = :gen_tcp.recv(socket, 0)
    assert data == "{\"method\":\"isPrime\",\"prime\":true}\n"
  end

  test "response to invalid request with malformed response" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5002, mode: :binary, active: false)
    assert :ok = :gen_tcp.send(socket, Jason.encode!(%{method: "malformed"}) <> "\n")
    {:ok, data} = :gen_tcp.recv(socket, 0)
    assert Jason.decode!(data) == "malformed request"
  end
end
