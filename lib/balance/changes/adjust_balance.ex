defmodule AshDoubleEntry.Balance.Changes.AdjustBalance do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, _, _) do
    amount_delta = changeset.arguments.delta

    new_balance =
      if changeset.data.account_id == changeset.arguments.from_account_id do
        Money.sub!(changeset.data.balance, amount_delta)
      else
        Money.add!(changeset.data.balance, amount_delta)
      end

    Ash.Changeset.force_change_attribute(changeset, :balance, new_balance)
  end

  def atomic(changeset, opts, _) do
    amount_delta = changeset.arguments.delta

    if Ash.Expr.expr?(amount_delta) do
      raise """
      Amount delta is dynamic. The balance adjustment logic does not support this.

      Expected a literal money value, got an expression: #{inspect(amount_delta)}
      """
    end

    if opts[:can_add_money?] do
      {:atomic,
       %{
         balance:
           expr(
             if account_id == ^changeset.arguments.from_account_id do
               ^atomic_ref(:balance) + -(^amount_delta)
             else
               ^atomic_ref(:balance) + ^amount_delta
             end
           )
       }}
    else
      {:not_atomic, "Data layer cannot add money, so balance cannot be adjusted atomically"}
    end
  end
end
