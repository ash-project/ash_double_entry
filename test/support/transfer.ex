# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Test.Transfer do
  @moduledoc false
  use Ash.Resource,
    domain: AshDoubleEntry.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Transfer]

  postgres do
    table "transfers"
    repo(AshDoubleEntry.Test.Repo)
  end

  transfer do
    account_resource AshDoubleEntry.Test.Account
    balance_resource AshDoubleEntry.Test.Balance
  end

  actions do
    defaults [:read, :destroy]

    update :update do
      accept [:amount]
      change get_and_lock_for_update()
      require_atomic? false
    end
  end
end
