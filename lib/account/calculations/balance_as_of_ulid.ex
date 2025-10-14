# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Account.Calculations.BalanceAsOfUlid do
  # Calculates the balance as of a given transfer id. See the getting started guide for more.
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
          query: [sort: [transfer_id: :desc], filter: transfer_id <= ^context.arguments[:ulid]]
        ) || composite_type(%{currency: currency, amount: 0}, AshMoney.Types.Money)
      )
    else
      Ash.Expr.expr(
        first(balances,
          field: :balance,
          query: [sort: [transfer_id: :desc], filter: transfer_id <= ^context.arguments[:ulid]]
        ) || %{currency: currency, amount: 0}
      )
    end
  end
end
