# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Test.Balance do
  @moduledoc false

  use Ash.Resource,
    domain: AshDoubleEntry.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Balance]

  defmodule RequiresPositiveBalance do
    @moduledoc false
    use Ash.Resource.Validation

    def validate(changeset, _, _) do
      account_id = Ash.Changeset.get_attribute(changeset, :account_id)

      if is_nil(account_id) do
        :ok
      else
        account =
          Ash.get!(AshDoubleEntry.Test.Account, account_id, authorize?: false)

        if account.allow_zero_balance do
          {:error, "Account must require positive balance"}
        else
          :ok
        end
      end
    end

    def atomic(_changeset, _, _) do
      {:atomic, [:account], expr(account.allow_zero_balance == true),
       expr(
         error(Ash.Error.Changes.InvalidRelationship,
           relationship: :account,
           message: "Account must require positive balance"
         )
       )}
    end
  end

  postgres do
    table "balances"
    repo(AshDoubleEntry.Test.Repo)

    references do
      reference(:transfer, on_delete: :delete)
    end
  end

  balance do
    transfer_resource AshDoubleEntry.Test.Transfer
    account_resource AshDoubleEntry.Test.Account
  end

  actions do
    defaults [:destroy]
  end

  validations do
    validate compare(:balance, greater_than_or_equal_to: 0),
      where: [RequiresPositiveBalance],
      message: "balance cannot be negative"
  end
end
