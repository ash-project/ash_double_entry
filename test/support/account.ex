# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Test.Account do
  @moduledoc false
  use Ash.Resource,
    domain: AshDoubleEntry.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Account]

  postgres do
    table "accounts"
    repo(AshDoubleEntry.Test.Repo)
  end

  account do
    pre_check_identities_with AshDoubleEntry.Test.Domain
    transfer_resource AshDoubleEntry.Test.Transfer
    balance_resource AshDoubleEntry.Test.Balance
    open_action_accept [:allow_zero_balance]
  end

  attributes do
    attribute :allow_zero_balance, :boolean do
      default true
    end
  end
end
