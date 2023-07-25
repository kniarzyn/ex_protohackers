defmodule ExProtohackers.QuotationServer.DB do
  def new(), do: []

  def insert(db, timestamp, price) do
    [{timestamp, price} | db]
  end

  def query(db, mintime, maxtime) do
    db
    |> Enum.filter(fn {time, _} -> time >= mintime && time <= maxtime end)
    |> Enum.map(fn {_, price} -> price end)
    |> case do
      [] -> 0
      prices -> Enum.sum(prices) / Enum.count(prices)
    end
  end
end
