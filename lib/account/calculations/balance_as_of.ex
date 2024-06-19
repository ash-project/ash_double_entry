defmodule AshDoubleEntry.Account.Calculations.BalanceAsOf do
  # Calculates the balance as of a given datetime. See the getting started guide for more.
  @moduledoc false
  use Ash.Resource.Calculation
  require Ash.Expr

  def expression(opts, context) do
    resource = opts[:resource]

    balance_resource = AshDoubleEntry.Account.Info.account_balance_resource!(resource)

    if AshDoubleEntry.Balance.Info.balance_money_composite_type?(balance_resource) do
      Ash.Expr.expr(
        first(balances,
          field: :balance,
          query: [sort: [transfer_id: :desc], filter: timestamp <= ^context.arguments[:timestamp]]
        ) || composite_type(%{currency: currency, amount: 0}, AshMoney.Types.Money)
      )
    else
      Ash.Expr.expr(
        first(balances,
          field: :balance,
          query: [sort: [transfer_id: :desc], filter: timestamp <= ^context.arguments[:timestamp]]
        ) || %{currency: currency, amount: 0}
      )
    end
  end
end
