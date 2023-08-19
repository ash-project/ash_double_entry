defmodule AshDoubleEntry.Transfer do
  @moduledoc """
  An extension for creating a double entry ledger transfer. See the getting started guide for more.
  """

  @account %Spark.Dsl.Section{
    name: :transfer,
    schema: [
      pre_check_identities_with: [
        type: {:spark, Ash.Api},
        doc: "An api to use to precheck generated identities. Required by certain data layers."
      ],
      account_resource: [
        type: Ash.OptionsHelpers.ash_resource(),
        doc: "The resource to use for account balances",
        required: true
      ],
      balance_resource: [
        type: {:spark, Ash.Resource},
        doc: "The resource being used for balances"
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
