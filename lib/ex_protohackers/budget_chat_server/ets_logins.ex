defmodule ExProtohackers.BudgetChatServer.ETSLogins do
  @table_name :logins
  def new() do
    :ets.new(@table_name, [:named_table, :ordered_set])
  end

  def put(login, socket) do
    :ets.insert(@table_name, {login, socket})
  end
end
