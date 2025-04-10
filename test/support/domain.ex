defmodule AshDoubleEntry.Test.Domain do
  use Ash.Domain

  resources do
    resource AshDoubleEntry.Test.Account
    resource AshDoubleEntry.Test.Transfer
    resource AshDoubleEntry.Test.Balance
  end
end
