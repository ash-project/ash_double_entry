defmodule AshDoubleEntry.Account do
  @account %Spark.Dsl.Section{
    name: :account
  }

  @sections [@account]

  @transformers [
    AshDoubleEntry.Account.Transformers.AddStructure
  ]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers
end
