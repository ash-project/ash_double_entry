defmodule AshDoubleEntry.Transfer.Transformers.AddStructure do
  use Spark.Dsl.Transformer

  def transform(dsl) do
    dsl
    |> Ash.Resource.Builder.add_attribute(:amount, :decimal,
      allow_nil?: false,
      default: Decimal.new(0),
      writable?: false
    )
    |> Ash.Resource.Builder.add_attribute(:converted_amount, :decimal, writable?: true)
    |> Ash.Resource.Builder.add_relationship(
      :belongs_to,
      :account,
      AshDoubleEntry.Transfer.Info.transfer_account_resource(dsl)
    )
  end
end
