defmodule AshDoubleEntry.Account.Preparations.LockForUpdate do
  # Locks the results of the query for update
  @moduledoc false
  use Ash.Resource.Preparation

  def prepare(query, _, _) do
    if Ash.DataLayer.data_layer_can?(query.resource, {:lock, :for_update}) do
      Ash.Query.lock(query, :for_update)
    else
      query
    end
  end
end
