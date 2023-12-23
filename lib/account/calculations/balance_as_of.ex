defmodule AshDoubleEntry.Account.Calculations.BalanceAsOf do
  # Calculates the balance as of a given datetime. See the getting started guide for more.
  @moduledoc false
  use Ash.Calculation
  require Ash.Expr

  def expression(opts, context) do
    Ash.Expr.expr(
      balance_as_of_ulid(
        ulid: Ash.Expr.expr(lazy({__MODULE__, :ulid, [context.timestamp]})),
        resource: opts[:resource]
      )
    )
  end

  @doc false
  def ulid(timestamp) do
    AshDoubleEntry.ULID.generate(timestamp)
  end
end
