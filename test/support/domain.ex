# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource AshDoubleEntry.Test.Account
    resource AshDoubleEntry.Test.Transfer
    resource AshDoubleEntry.Test.Balance
  end
end
