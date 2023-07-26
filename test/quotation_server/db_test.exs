defmodule ExProtohackers.QuotationServer.DBTest do
  use ExUnit.Case

  alias ExProtohackers.QuotationServer.DB

  test "DB handles inserts and queries" do
    db =
      DB.new()
      |> DB.insert(1, 100)
      |> DB.insert(2, 200)
      |> DB.insert(3, 300)

    assert db = [{1, 100}, {2, 200}, {3, 300}]

    assert DB.query(db, 1, 3) == 200
    assert DB.query(db, 1, 1) == 100
    assert DB.query(db, 2, 3) == 250
    assert DB.query(db, 7, 9) == 0
  end
end
