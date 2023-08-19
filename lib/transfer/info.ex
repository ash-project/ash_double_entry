defmodule AshDoubleEntry.Transfer.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Transfer`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Transfer, sections: [:transfer]
end
