defmodule AshDoubleEntry.Account.Calculations.BalanceAsOf do
  # Calculates the balance as of a given datetime. See the getting started guide for more.
  @moduledoc false
  use Ash.Calculation
  require Ash.Expr

  def expression(opts, context) do
    ulid = AshDoubleEntry.ULID.generate(context.timestamp)

    Ash.Expr.expr(balance_as_of_ulid(ulid: ulid, resource: opts[:resource]))
  end
end
