defmodule AshDoubleEntry.Balance.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Balance`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Balance, sections: [:balance]
end
