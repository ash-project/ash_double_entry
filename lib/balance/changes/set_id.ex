defmodule AshDoubleEntry.Balance.Changes.SetId do
  use Ash.Resource.Change

  def change(changeset, opts, _context) do
    from = opts[:from]
    to = opts[:to]
    source = Ash.Changeset.get_argument(changeset, from)

    case source do
      %{id: id} ->
        Ash.Changeset.force_change_attribute(changeset, to, id)

      _ ->
        changeset
    end
  end
end
