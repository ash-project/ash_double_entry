defmodule AshDoubleEntry.Transfer do
  @moduledoc """
  An extension for creating a double entry ledger transfer. See the getting started guide for more.
  """

  @account %Spark.Dsl.Section{
    name: :transfer,
    schema: [
      pre_check_identities_with: [
        type: {:spark, Ash.Domain},
        doc: "A domain to use to precheck generated identities. Required by certain data layers."
      ],
      account_resource: [
        type: Ash.OptionsHelpers.ash_resource(),
        doc: "The resource to use for account balances",
        required: true
      ],
      balance_resource: [
        type: {:spark, Ash.Resource},
        doc: "The resource being used for balances"
      ],
      create_accept: [
        type: {:wrap_list, :atom},
        doc: "Additional attributes to accept when creating a transfer"
      ],
      primary_key_type: [
        type: Ash.OptionsHelpers.ash_type(),
        default: :uuid,
        doc: "The primary key type to use."
      ],
      primary_key_generator: [
        type: {:function, 0},
        default: &Ash.UUID.generate/0,
        doc:
          "A function that generates a primary key for the transfer. Set automatically if primary key type is `AshDoubleEntry.ULID`."
      ],
      primary_key_generator_with_timestamp: [
        type: {:function, 1},
        doc:
          "A function that generates a primary key for the transfer with a timestamp. Set automatically if primary key type is `AshDoubleEntry.ULID`."
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
