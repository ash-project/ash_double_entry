defmodule AshDoubleEntry.Account.Info do
  use Spark.InfoGenerator, extension: AshDoubleEntry.Account, sections: [:account]
end
