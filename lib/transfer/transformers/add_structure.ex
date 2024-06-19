defmodule AshDoubleEntry.Transfer.Transformers.AddStructure do
  # Adds all the structure required for the resource. See the getting started guide for more.
  @moduledoc false
  use Spark.Dsl.Transformer

  def before?(Ash.Resource.Transformers.CachePrimaryKey), do: true
  def before?(Ash.Resource.Transformers.BelongsToSourceField), do: true
  def before?(Ash.Resource.Transformers.BelongsToAttribute), do: true
  def before?(_), do: false

  def transform(dsl) do
    primary_key_type = AshDoubleEntry.Transfer.Info.transfer_primary_key_type!(dsl)

    generator =
      case AshDoubleEntry.Transfer.Info.transfer_primary_key_generator(dsl) do
        {:ok, generator} ->
          generator

        :error ->
          if primary_key_type == AshDoubleEntry.ULID do
            &AshDoubleEntry.ULID.generate/0
          else
            raise Spark.Error.DslError,
              module: Spark.Dsl.Transformer.get_persisted(dsl, :module),
              path: [:transfer, :primary_key_generator],
              message:
                "Must configure a primary key generator if customizing the primary key type"
          end
      end

    dsl =
      case AshDoubleEntry.Transfer.Info.transfer_primary_key_generator_with_timestamp(dsl) do
        :error ->
          if primary_key_type == AshDoubleEntry.ULID do
            Spark.Dsl.Transformer.set_option(
              dsl_state,
              [:transfer, :primary_key_generator_with_timestamp],
              &AshDoubleEntry.ULID.generate/1
            )
          else
            dsl
          end

        _ ->
          dsl
      end

    dsl
    |> Ash.Resource.Builder.add_new_attribute(:id, primary_key_type,
      primary_key?: true,
      allow_nil?: false,
      default: generator,
      generated?: false
    )
    |> Ash.Resource.Builder.add_new_attribute(:amount, AshMoney.Types.Money, allow_nil?: false)
    |> Ash.Resource.Builder.add_new_attribute(:timestamp, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0
    )
    |> Ash.Resource.Builder.add_new_attribute(:inserted_at, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0
    )
    |> Ash.Resource.Builder.add_new_relationship(
      :belongs_to,
      :from_account,
      AshDoubleEntry.Transfer.Info.transfer_account_resource!(dsl),
      attribute_writable?: true
    )
    |> Ash.Resource.Builder.add_new_relationship(
      :belongs_to,
      :to_account,
      AshDoubleEntry.Transfer.Info.transfer_account_resource!(dsl),
      attribute_writable?: true
    )
    |> Ash.Resource.Builder.add_action(:create, :transfer,
      accept:
        [:amount, :timestamp, :from_account_id, :to_account_id] ++
          AshDoubleEntry.Transfer.Info.transfer_create_accept!(dsl)
    )
    |> Ash.Resource.Builder.add_action(:read, :read_transfers,
      pagination: Ash.Resource.Builder.build_pagination(keyset?: true)
    )
    |> Ash.Resource.Builder.add_change({AshDoubleEntry.Transfer.Changes.VerifyTransfer, []},
      on: [:create, :update, :destroy]
    )
  end
end
