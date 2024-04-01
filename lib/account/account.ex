defmodule AshDoubleEntry.Account do
  @moduledoc """
  An extension for creating a double entry ledger account. See the getting started guide for more.
  """

  @account %Spark.Dsl.Section{
    name: :account,
    schema: [
      open_action_accept: [
        type: {:list, :atom},
        doc: """
        A list of extra attributes to be accepted by the open action. The `identifier` and `currency` attributes are always accepted.
        """,
        default: []
      ],
      pre_check_identities_with: [
        type: {:spark, Ash.Domain},
        doc: "A domain to use to precheck generated identities. Required by certain data layers."
      ],
      transfer_resource: [
        type: {:spark, Ash.Resource},
        doc: "The resource used for transfers",
        required: true
      ],
      balance_resource: [
        type: {:spark, Ash.Resource},
        doc: "The resource used for balances",
        required: true
      ]
    ]
  }

  @sections [@account]

  @transformers [
    AshDoubleEntry.Account.Transformers.AddStructure
  ]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers
end
