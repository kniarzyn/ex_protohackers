defmodule ExProtohackers.BudgetChatServer.ETSLoginsTest do
  use ExUnit.Case

  alias ElixirLS.LanguageServer.ExUnitTestTracer
  alias ExProtohackers.BudgetChatServer.ETSLogins

  test "stores uniq {login, socket}" do
    table = ETSLogins.new()
    ETSLogins.put("anna", "PID123")
    ETSLogins.put("Roman", "PID222")

    assert :ets.tab2list(table) == [{"Roman", "PID222"}, {"anna", "PID123"}]
  end
end

