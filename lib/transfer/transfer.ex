defmodule AshDoubleEntry.Transfer do
  @account %Spark.Dsl.Section{
    name: :transfer,
    schema: [
      account_resource: [
        type: Ash.OptionsHelpers.ash_resource(),
        doc: "The resource to use for account balances",
        required: true
      ]
    ]
  }

  @sections [@account]

  @transformers [
    AshDoubleEntry.Transfer.Transformers.AddStructure
  ]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers
end
