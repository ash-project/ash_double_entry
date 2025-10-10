# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Transfer.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Transfer`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Transfer, sections: [:transfer]
end
