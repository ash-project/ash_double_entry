# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Balance.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Balance`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Balance, sections: [:balance]
end
