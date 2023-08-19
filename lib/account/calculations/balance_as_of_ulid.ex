defmodule AshDoubleEntry.Account.Calculations.BalanceAsOfUlid do
  @moduledoc """
  Calculates the balance as of a given transfer id. See the getting started guide for more.
  """
  use Ash.Calculation
  require Ash.Expr

  def expression(opts, context) do
    resource = opts[:resource]

    ref = %Ash.Query.Ref{
      attribute:
        Ash.Query.Aggregate.new!(resource, :balance_as_of_ulid_agg, :first,
          field: :balance,
          path: [:balances],
          default: Decimal.new(0),
          query: [
            filter: [
              transfer_id: [lt: context[:ulid]]
            ],
            sort: [
              transfer_id: :desc
            ]
          ]
        ),
      relationship_path: [],
      resource: resource
    }

    Ash.Expr.expr(^ref)
  end
end
