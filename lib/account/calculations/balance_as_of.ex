# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Account.Calculations.BalanceAsOf do
  # Calculates the balance as of a given datetime. See the getting started guide for more.
  @moduledoc false
  use Ash.Resource.Calculation
  require Ash.Expr

  def expression(_opts, context) do
    Ash.Expr.expr(
      balance_as_of_ulid(ulid: lazy({__MODULE__, :ulid, [context.arguments.timestamp]}))
    )
  end

  @doc false
  def ulid(timestamp) do
    AshDoubleEntry.ULID.generate_last(timestamp)
  end
end
