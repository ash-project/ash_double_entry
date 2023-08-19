defmodule AshDoubleEntry.Account.Transformers.AddStructure do
  use Spark.Dsl.Transformer
  import Spark.Dsl.Builder

  def before?(Ash.Resource.Transformers.CachePrimaryKey), do: true
  def before?(_), do: false

  def transform(dsl) do
    dsl
    |> add_primary_read_action()
    |> Ash.Resource.Builder.add_attribute(:id, :uuid,
      primary_key?: true,
      writable?: false,
      generated?: true,
      allow_nil?: false,
      default: &Ash.UUID.generate/0
    )
    |> Ash.Resource.Builder.add_attribute(:identifier, :string, allow_nil?: false)
    |> Ash.Resource.Builder.add_attribute(
      :currency,
      :string,
      allow_nil?: false
    )
    |> Ash.Resource.Builder.add_action(:create, :open,
      accept:
        Enum.uniq(
          [:identifier, :currency] ++ AshDoubleEntry.Account.Info.account_open_action_accept!(dsl)
        )
    )
    |> Ash.Resource.Builder.add_action(:read, :lock_accounts,
      preparations: [
        Ash.Resource.Builder.build_preparation(
          {AshDoubleEntry.Account.Preparations.LockForUpdate, []}
        )
      ]
    )
    |> Ash.Resource.Builder.add_attribute(:inserted_at, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0
    )
    |> Ash.Resource.Builder.add_aggregate(:balance, :first, [:balances],
      field: :balance,
      default: Decimal.new(0),
      sort: [transfer_id: :desc]
    )
    |> Ash.Resource.Builder.add_relationship(
      :has_many,
      :balances,
      AshDoubleEntry.Account.Info.account_balance_resource!(dsl),
      destination_attribute: :account_id
    )
    |> add_balance_as_of_ulid_calculation()
    |> add_balance_as_of_calculation()
    |> Ash.Resource.Builder.add_identity(:unique_identifier, [:identifier],
      pre_check_with: pre_check_with(dsl)
    )
  end

  defbuilder add_balance_as_of_ulid_calculation(dsl) do
    Ash.Resource.Builder.add_calculation(
      dsl,
      :balance_as_of_ulid,
      :decimal,
      {AshDoubleEntry.Account.Calculations.BalanceAsOfUlid,
       [resource: Spark.Dsl.Transformer.get_persisted(dsl, :module)]},
      private?: true,
      arguments: [
        Ash.Resource.Builder.build_calculation_argument(
          :ulid,
          AshDoubleEntry.ULID,
          allow_nil?: false
        )
      ]
    )
  end

  defbuilder add_balance_as_of_calculation(dsl) do
    Ash.Resource.Builder.add_calculation(
      dsl,
      :balance_as_of,
      :decimal,
      {AshDoubleEntry.Account.Calculations.BalanceAsOfUlid,
       [resource: Spark.Dsl.Transformer.get_persisted(dsl, :module)]},
      private?: true,
      arguments: [
        Ash.Resource.Builder.build_calculation_argument(
          :timestamp,
          :utc_datetime_usec,
          allow_nil?: false
        )
      ]
    )
  end

  defbuilder add_primary_read_action(dsl) do
    if Ash.Resource.Info.primary_action(dsl, :read) do
      {:ok, dsl}
    else
      Ash.Resource.Builder.add_action(dsl, :read, :_autogenerated_primary_read,
        primary?: true,
        pagination: Ash.Resource.Builder.build_pagination(keyset?: true)
      )
    end
  end

  defp pre_check_with(dsl) do
    case AshDoubleEntry.Account.Info.account_pre_check_identities_with(dsl) do
      :error ->
        nil

      {:ok, value} ->
        value
    end
  end
end
