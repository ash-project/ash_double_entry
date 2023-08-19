defmodule AshDoubleEntry.Transfer.Changes.VerifyTransfer do
  @moduledoc """
  Verify a transfer and update all related balances of the accounts involved.

  This operation locks the accounts involved, serializing all transfers between
  relevant accounts.
  """
  use Ash.Resource.Change
  require Ash.Query

  def change(changeset, _opts, context) do
    changeset
    |> Ash.Changeset.before_action(fn changeset ->
      from_account_id = Ash.Changeset.get_attribute(changeset, :from_account_id)
      to_account_id = Ash.Changeset.get_attribute(changeset, :to_account_id)
      amount = Ash.Changeset.get_attribute(changeset, :amount)
      timestamp = Ash.Changeset.get_attribute(changeset, :timestamp)

      timestamp =
        case timestamp do
          nil -> System.system_time(:millisecond)
          timestamp -> DateTime.to_unix(timestamp, :millisecond)
        end

      ulid = AshDoubleEntry.ULID.generate(timestamp)

      accounts =
        changeset.resource
        |> AshDoubleEntry.Transfer.Info.transfer_account_resource!()
        |> Ash.Query.filter(id in ^[from_account_id, to_account_id])
        |> Ash.Query.for_read(:lock_accounts)
        |> Ash.Query.load(balance_as_of_ulid: %{ulid: ulid})
        |> changeset.api.read!(authorize?: false, tracer: context[:tracer])

      from_account = Enum.find(accounts, &(&1.id == from_account_id))
      to_account = Enum.find(accounts, &(&1.id == to_account_id))

      new_from_account_balance =
        Decimal.sub(from_account.balance_as_of_ulid, amount)

      new_to_account_balance =
        Decimal.add(to_account.balance_as_of_ulid, amount)

      changeset.resource
      |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()
      |> Ash.Changeset.for_create(
        :upsert_balance,
        %{
          account_id: from_account.id,
          transfer_id: ulid,
          balance: new_from_account_balance,
          account: from_account
        },
        context_to_opts(context)
      )
      |> changeset.api.create!()

      changeset.resource
      |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()
      |> Ash.Changeset.for_create(
        :upsert_balance,
        %{
          account_id: to_account.id,
          transfer_id: ulid,
          balance: new_to_account_balance
        },
        context_to_opts(context)
      )
      |> changeset.api.create!()

      changeset
      |> Ash.Changeset.force_change_attribute(:id, ulid)
      |> Ash.Changeset.set_context(%{
        from_account: from_account,
        to_account: to_account,
        amount: amount
      })
    end)
    |> Ash.Changeset.after_action(fn changeset, result ->
      # Turn this into a bulk update when we support it in Ash core
      changeset.resource
      |> AshDoubleEntry.Transfer.Info.transfer_balance_resource!()
      |> Ash.Query.filter(
        account_id in ^[changeset.context.from_account.id, changeset.context.to_account.id]
      )
      |> Ash.Query.filter(transfer_id > ^result.id)
      |> changeset.api.stream!()
      |> Stream.map(fn balance ->
        if balance.account_id == changeset.context.from_account.id do
          %{
            account_id: balance.account_id,
            transfer_id: balance.transfer_id,
            balance: Decimal.sub(balance.balance, changeset.context.amount)
          }
        else
          %{
            account_id: balance.account_id,
            transfer_id: balance.transfer_id,
            balance: Decimal.add(balance.balance, changeset.context.amount)
          }
        end
      end)
      |> changeset.api.bulk_create!(
        AshDoubleEntry.Transfer.Info.transfer_balance_resource!(changeset.resource),
        :upsert_balance,
        context_to_opts(context,
          return_errors?: true,
          stop_on_error?: true,
          upsert_fields: [:balance]
        )
      )

      {:ok, result}
    end)
  end

  defp context_to_opts(context, opts \\ []) do
    context
    |> Map.take([:tenant, :actor, :tracer])
    |> Map.to_list()
    |> Keyword.merge(opts)
  end
end
