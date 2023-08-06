defmodule AshDoubleEntry.Account.Calculations.BalanceAsOf do
  use Ash.Calculation
  require Ash.Expr

  def expression(opts, context) do
    resource = opts[:resource]

    ulid = AshDoubleEntry.ULID.generate(context.timestamp)

    ref = %Ash.Query.Ref{
      attribute:
        Ash.Query.Aggregate.new!(resource, {:balance_as_of_date_agg, context[:ulid]}, :first,
          field: :balance,
          path: [:balances],
          default: Decimal.new(0),
          query: [
            filter: [
              transfer_id: [gt: ulid]
            ],
            sort: [
              transfer_id: :desc
            ]
          ]
        ),
      relationship_path: [],
      resource: resource
    }

    Ash.Expr.expr(^ref || ^Decimal.new(0))
  end
end
