defmodule AshDoubleEntry.Test.Transfer do
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
    defaults [:read, :destroy, update: [:amount]]
  end
end
