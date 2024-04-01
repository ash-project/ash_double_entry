defmodule AshDoubleEntry.Transfer.Changes.VerifyTransfer do
  # Verify a transfer and update all related balances of the accounts involved.

  # This operation locks the accounts involved, serializing all transfers between
  # relevant accounts.

  @moduledoc false
  use Ash.Resource.Change
  require Ash.Query

  def change(changeset, _opts, context) do
    if changeset.action.type == :update and
         Enum.any?(
           [:from_account_id, :to_account_id, :id],
           &Ash.Changeset.changing_attribute?(changeset, &1)
         ) do
      Ash.Changeset.add_error(
        changeset,
        "Cannot modify a transfer's from_account_id, to_account_id, or id"
      )
    else
      changeset
      |> Ash.Changeset.before_action(fn changeset ->
        if changeset.action.type == :create do
          timestamp = Ash.Changeset.get_attribute(changeset, :timestamp)

          timestamp =
            case timestamp do
              nil -> System.system_time(:millisecond)
              timestamp -> DateTime.to_unix(timestamp, :millisecond)
            end

          ulid = AshDoubleEntry.ULID.generate(timestamp)

          Ash.Changeset.force_change_attribute(changeset, :id, ulid)
        else
          changeset
        end
      end)
      |> maybe_destroy_balances(context)
      |> Ash.Changeset.after_action(fn changeset, result ->
        from_account_id = Ash.Changeset.get_attribute(changeset, :from_account_id)
        to_account_id = Ash.Changeset.get_attribute(changeset, :to_account_id)
        new_amount = Ash.Changeset.get_attribute(changeset, :amount)

        old_amount =
          if changeset.action.type == :destroy do
            Money.new!(0, new_amount.currency)
          else
            changeset.data.amount || Money.new!(0, new_amount.currency)
          end

        amount_delta =
          Money.sub!(new_amount, old_amount)

        accounts =
          changeset.resource
          |> AshDoubleEntry.Transfer.Info.transfer_account_resource!()
          |> Ash.Query.filter(id in ^[from_account_id, to_account_id])
          |> Ash.Query.for_read(
            :lock_accounts,
            %{},
            Ash.Context.to_opts(context, authorize?: false, domain: changeset.domain)
          )
          |> Ash.Query.load(balance_as_of_ulid: %{ulid: result.id})
          |> Ash.read!()

        from_account = Enum.find(accounts, &(&1.id == from_account_id))
        to_account = Enum.find(accounts, &(&1.id == to_account_id))

        new_from_account_balance =
          Money.sub!(
            from_account.balance_as_of_ulid || Money.new!(0, from_account.currency),
            amount_delta
          )

        new_to_account_balance =
          Money.add!(
            to_account.balance_as_of_ulid || Money.new!(0, to_account.currency),
            amount_delta
          )

        unless changeset.action.type == :destroy do
          changeset.resource
          |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()
          |> Ash.Changeset.for_create(
            :upsert_balance,
            %{
              account_id: from_account.id,
              transfer_id: result.id,
              balance: new_from_account_balance,
              account: from_account
            },
            Ash.Context.to_opts(context,
              domain: changeset.domain,
              skip_unknown_inputs: [:account_id, :transfer_id, :balance, :account]
            )
          )
          |> Ash.create!()

          changeset.resource
          |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()
          |> Ash.Changeset.for_create(
            :upsert_balance,
            %{
              account_id: to_account.id,
              transfer_id: result.id,
              balance: new_to_account_balance
            },
            Ash.Context.to_opts(context,
              domain: changeset.domain,
              skip_unknown_inputs: [:account_id, :transfer_id, :balance]
            )
          )
          |> Ash.create!()
        end

        # Turn this into a bulk update when we support it in Ash core
        changeset.resource
        |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()
        |> Ash.Query.filter(account_id in ^[from_account.id, to_account.id])
        |> Ash.Query.filter(transfer_id > ^result.id)
        |> Ash.stream!(Ash.Context.to_opts(context, domain: changeset.domain))
        |> Stream.map(fn balance ->
          amount_delta =
            if changeset.action.type == :destroy do
              Money.mult!(amount_delta, -1)
            else
              amount_delta
            end

          if balance.account_id == from_account.id do
            %{
              account_id: balance.account_id,
              transfer_id: balance.transfer_id,
              balance: Money.sub!(balance.balance, amount_delta)
            }
          else
            %{
              account_id: balance.account_id,
              transfer_id: balance.transfer_id,
              balance: Money.add!(balance.balance, amount_delta)
            }
          end
        end)
        |> Ash.bulk_create!(
          AshDoubleEntry.Transfer.Info.transfer_balance_resource!(changeset.resource),
          :upsert_balance,
          Ash.Context.to_opts(context,
            domain: changeset.domain,
            return_errors?: true,
            stop_on_error?: true,
            upsert_fields: [:balance]
          )
        )

        {:ok, result}
      end)
    end
  end

  defp maybe_destroy_balances(changeset, context) do
    if changeset.action.type == :destroy do
      balance_resource =
        changeset.resource
        |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()

      destroy_action = Ash.Resource.Info.primary_action(balance_resource, :destroy)

      if !destroy_action do
        raise "Must configure a primary destroy action for #{inspect(balance_resource)} to destroy transactions"
      end

      Ash.Changeset.before_action(changeset, fn changeset ->
        balance_resource
        |> Ash.Query.filter(transfer_id == ^changeset.data.id)
        |> Ash.stream!(Ash.Context.to_opts(context, authorize?: false, domain: changeset.domain))
        |> Enum.each(fn balance ->
          balance
          |> Ash.Changeset.for_destroy(
            destroy_action,
            %{},
            Ash.Context.to_opts(context, authorize?: false, domain: changeset.domain)
          )
          |> Ash.destroy!()
        end)

        changeset
      end)
    else
      changeset
    end
  end
end
