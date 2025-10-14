# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Account.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Account`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Account, sections: [:account]
end
