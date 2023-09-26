defmodule AshDoubleEntry.Transfer.Transformers.AddStructure do
  # Adds all the structure required for the resource. See the getting started guide for more.
  @moduledoc false
  use Spark.Dsl.Transformer

  def before?(Ash.Resource.Transformers.CachePrimaryKey), do: true
  def before?(Ash.Resource.Transformers.BelongsToSourceField), do: true
  def before?(Ash.Resource.Transformers.BelongsToAttribute), do: true
  def before?(_), do: false

  def transform(dsl) do
    dsl
    |> Ash.Resource.Builder.add_attribute(:id, AshDoubleEntry.ULID,
      primary_key?: true,
      allow_nil?: false,
      default: &AshDoubleEntry.ULID.generate/0,
      generated?: false
    )
    |> Ash.Resource.Builder.add_attribute(:amount, :decimal, allow_nil?: false)
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
    |> Ash.Resource.Builder.add_action(:create, :transfer,
      accept: [:amount, :timestamp, :from_account_id, :to_account_id]
    )
    |> Ash.Resource.Builder.add_action(:read, :read_transfers,
      pagination: Ash.Resource.Builder.build_pagination(keyset?: true)
    )
    |> Ash.Resource.Builder.add_change({AshDoubleEntry.Transfer.Changes.VerifyTransfer, []})
  end
end
