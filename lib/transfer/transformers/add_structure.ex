defmodule AshDoubleEntry.Transfer.Transformers.AddStructure do
  use Spark.Dsl.Transformer

  def before?(Ash.Resource.Transformers.CachePrimaryKey), do: true
  def before?(_), do: false

  def transform(dsl) do
    dsl
    |> Ash.Resource.Builder.add_attribute(:id, AshDoubleEntry.ULID,
      primary_key?: true,
      allow_nil?: false,
      default: &AshDoubleEntry.ULID.generate/0,
      generated?: false
    )
    |> Ash.Resource.Builder.add_attribute(:from_amount, :decimal, allow_nil?: false)
    |> Ash.Resource.Builder.add_attribute(:to_amount, :decimal, allow_nil?: false)
    |> Ash.Resource.Builder.add_attribute(:timestamp, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0
    )
    |> Ash.Resource.Builder.add_attribute(:inserted_at, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0
    )
    |> Ash.Resource.Builder.add_relationship(
      :belongs_to,
      :from_account,
      AshDoubleEntry.Transfer.Info.transfer_account_resource!(dsl),
      attribute_writable?: true
    )
    |> Ash.Resource.Builder.add_relationship(
      :belongs_to,
      :to_account,
      AshDoubleEntry.Transfer.Info.transfer_account_resource!(dsl),
      attribute_writable?: true
    )
    |> Ash.Resource.Builder.add_change({AshDoubleEntry.Transfer.Changes.VerifyTransfer, []})
    |> Ash.Resource.Builder.add_action(:create, :transfer,
      accept: [:to_amount, :from_amount, :timestamp, :from_account_id, :to_account_id],
      allow_nil_input: [:to_amount, :from_amount],
      arguments: [
        Ash.Resource.Builder.build_action_argument(:amount, :decimal)
      ],
      changes: [
        Ash.Resource.Builder.build_action_change({AshDoubleEntry.Transfer.Changes.SetAmounts, []})
      ]
    )
    |> Ash.Resource.Builder.add_action(:read, :read_transfers,
      pagination: Ash.Resource.Builder.build_pagination(keyset?: true)
    )
  end
end
