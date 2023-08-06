defmodule AshDoubleEntry.Transfer.Changes.SetAmounts do
  use Ash.Resource.Change

  def change(changeset, _, _) do
    case Ash.Changeset.fetch_argument(changeset, :amount) do
      {:ok, amount} when not is_nil(amount) ->
        changeset
        |> Ash.Changeset.force_change_new_attribute(:to_amount, amount)
        |> Ash.Changeset.force_change_new_attribute(:from_amount, amount)

      _ ->
        cond do
          is_nil(Ash.Changeset.get_attribute(changeset, :to_amount)) ->
            {:error,
             Ash.Error.Changes.Required.exception(
               field: :to_amount,
               type: :attribute,
               resource: changeset.resource
             )}

          is_nil(Ash.Changeset.get_attribute(changeset, :from_amount)) ->
            {:error,
             Ash.Error.Changes.Required.exception(
               field: :from_amount,
               type: :attribute,
               resource: changeset.resource
             )}

          true ->
            changeset
        end
    end
  end
end
