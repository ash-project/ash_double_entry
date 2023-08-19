defmodule AshDoubleEntry.Balance do
  @moduledoc """
  An extension for creating a double entry ledger balance. See the getting started guide for more.
  """

  @balance %Spark.Dsl.Section{
    name: :balance,
    schema: [
      pre_check_identities_with: [
        type: {:spark, Ash.Api},
        doc: "An api to use to precheck generated identities. Required by certain data layers."
      ],
      transfer_resource: [
        type: {:spark, Ash.Resource},
        doc: "The resource used for transfers",
        required: true
      ],
      account_resource: [
        type: {:spark, Ash.Resource},
        doc: "The resource used for accounts",
        required: true
      ]
    ]
  }

  @sections [@balance]

  @transformers [
    AshDoubleEntry.Balance.Transformers.AddStructure
  ]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers
end
