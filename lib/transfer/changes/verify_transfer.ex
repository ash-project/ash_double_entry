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

          id =
            case AshDoubleEntry.Transfer.Info.primary_key_generator_with_timestamp(
                   changeset.resource
                 ) do
              {:ok, generator} ->
                generator.(timestamp)

              _ ->
                AshDoubleEntry.Transfer.Info.primary_key_generator!(changeset.resource).()
            end

          Ash.Changeset.force_change_attribute(changeset, :id, id)
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
          |> Ash.Query.set_context(%{ash_double_entry?: true})
          |> Ash.Query.for_read(
            :lock_accounts,
            %{},
            Ash.Context.to_opts(context,
              authorize?: authorize?(changeset.domain),
              domain: changeset.domain
            )
          )
          |> Ash.Query.load(balance_as_of: %{timestamp: result.timestamp})
          |> Ash.read!()

        from_account = Enum.find(accounts, &(&1.id == from_account_id))
        to_account = Enum.find(accounts, &(&1.id == to_account_id))

        new_from_account_balance =
          Money.sub!(
            from_account.balance_as_of || Money.new!(0, from_account.currency),
            amount_delta
          )

        new_to_account_balance =
          Money.add!(
            to_account.balance_as_of || Money.new!(0, to_account.currency),
            amount_delta
          )

        balance_resource =
          AshDoubleEntry.Transfer.Info.transfer_balance_resource!(changeset.resource)

        bulk_destroy_errors =
          unless changeset.action.type == :destroy do
            Ash.bulk_create(
              [
                %{
                  account_id: from_account.id,
                  transfer_id: result.id,
                  balance: new_from_account_balance
                },
                %{
                  account_id: to_account.id,
                  transfer_id: result.id,
                  balance: new_to_account_balance
                }
              ],
              balance_resource,
              :upsert_balance,
              Ash.Context.to_opts(context,
                domain: changeset.domain,
                upsert_fields: [:balance],
                return_errors?: true,
                stop_on_error?: true
              )
            )
          end
          |> case do
            nil ->
              []

            %Ash.BulkResult{status: :success} ->
              []

            %Ash.BulkResult{errors: errors} ->
              errors
          end

        case bulk_destroy_errors do
          [] ->
            amount_delta =
              if changeset.action.type == :destroy do
                Money.mult!(amount_delta, -1)
              else
                amount_delta
              end

            Ash.bulk_update(
              balance_resource,
              :adjust_balance,
              %{
                from_account_id: from_account.id,
                to_account_id: to_account.id,
                transfer_id: result.id,
                delta: amount_delta
              },
              Ash.Context.to_opts(context,
                domain: changeset.domain,
                strategy: [:atomic, :stream, :atomic_batches],
                return_errors?: true,
                stop_on_error?: true
              )
              |> Keyword.update(
                :context,
                %{ash_double_entry?: true},
                &Map.put(&1, :ash_double_entry?, true)
              )
            )
            |> case do
              %Ash.BulkResult{status: :success} -> {:ok, result}
              %Ash.BulkResult{errors: errors} -> {:error, errors}
            end

          errors ->
            {:error, errors}
        end
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
        |> Ash.Query.set_context(%{ash_double_entry?: true})
        |> Ash.bulk_destroy(
          destroy_action,
          %{},
          Ash.Context.to_opts(context,
            authorize?: authorize?(changeset.domain),
            domain: changeset.domain,
            strategy: [:stream, :atomic, :atomic_batches]
          )
        )
        |> case do
          %Ash.BulkResult{status: :success} -> changeset
          %Ash.BulkResult{errors: errors} -> {:error, Ash.Changeset.add_error(changeset, errors)}
        end
      end)
    else
      changeset
    end
  end

  defp authorize?(domain), do: Ash.Domain.Info.authorize(domain) == :always
end
