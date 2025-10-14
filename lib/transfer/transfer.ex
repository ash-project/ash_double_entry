# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs.contributors>
#
# SPDX-License-Identifier: MIT

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
        default: [],
        doc: "Additional attributes to accept when creating a transfer"
      ],
      destroy_balances?: [
        type: :boolean,
        doc:
          "Whether or not balances must be manually destroyed. See the getting started guide for more.",
        default: false
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
