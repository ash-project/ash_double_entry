# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Account.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Account`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Account, sections: [:account]
end
