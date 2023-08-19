defmodule AshDoubleEntry.Account.Info do
  @moduledoc "Introspection helpers for `AshDoubleEntry.Account`"
  use Spark.InfoGenerator, extension: AshDoubleEntry.Account, sections: [:account]
end
