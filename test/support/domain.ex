# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs.contributors>
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
