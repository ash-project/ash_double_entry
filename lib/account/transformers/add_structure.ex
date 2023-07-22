defmodule AshDoubleEntry.Account.Transformers.AddStructure do
  use Spark.Dsl.Transformer

  def transform(dsl) do
    dsl
    |> Ash.Resource.Builder.add_attribute(:balance, :decimal,
      allow_nil?: false,
      default: Decimal.new(0),
      writable?: false
    )
    |> Ash.Resource.Builder.add_attribute(
      :currency,
      :string,
      allow_nil?: false
    )
  end
end
