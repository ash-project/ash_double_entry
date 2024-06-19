defmodule AshDoubleEntry.Balance do
  @moduledoc """
  An extension for creating a double entry ledger balance. See the getting started guide for more.
  """

  @balance %Spark.Dsl.Section{
    name: :balance,
    schema: [
      pre_check_identities_with: [
        type: {:spark, Ash.Domain},
        doc: "A domain to use to precheck generated identities. Required by certain data layers."
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
      ],
      money_composite_type?: [
        type: :boolean,
        doc: "Whether the balance is stored as a composite type.",
        default: true
      ],
      data_layer_can_add_money?: [
        type: :boolean,
        doc: "Whether or not the data layer supports adding money.",
        default: true
      ],
      transfer_primary_key_type: [
        type: Ash.OptionsHelpers.type(),
        default: :uuid,
        doc: "The type of the primary key for the transfer resource."
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
