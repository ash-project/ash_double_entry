defmodule AshDoubleEntry.Balance.Info do
  use Spark.InfoGenerator, extension: AshDoubleEntry.Balance, sections: [:balance]
end
