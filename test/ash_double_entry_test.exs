defmodule AshDoubleEntryTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Ash.Query

  defmodule Account do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Mnesia,
      extensions: [AshDoubleEntry.Account]

    account do
      pre_check_identities_with AshDoubleEntryTest.Api
      transfer_resource AshDoubleEntryTest.Transfer
      balance_resource AshDoubleEntryTest.Balance
      open_action_accept [:allow_zero_balance]
    end

    attributes do
      attribute :allow_zero_balance, :boolean do
        default true
      end
    end
  end

  defmodule Transfer do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Mnesia,
      extensions: [AshDoubleEntry.Transfer]

    transfer do
      account_resource Account
      balance_resource AshDoubleEntryTest.Balance
    end
  end

  defmodule Balance do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Mnesia,
      extensions: [AshDoubleEntry.Balance]

    balance do
      pre_check_identities_with AshDoubleEntryTest.Api
      transfer_resource Transfer
      account_resource Account
    end

    changes do
      change after_action(&validate_balance/2)
    end

    defp validate_balance(changeset, result) do
      account = result |> changeset.api.load!(:account) |> Map.get(:account)

      if account.allow_zero_balance == false &&
           Money.negative?(result.balance) do
        {:error,
         Ash.Error.Changes.InvalidAttribute.exception(
           value: result.balance,
           field: :balance,
           message: "balance cannot be negative"
         )}
      else
        {:ok, result}
      end
    end
  end

  defmodule Api do
    use Ash.Api

    resources do
      resource Account
      resource Transfer
      resource Balance
    end
  end

  setup do
    Ash.DataLayer.Mnesia.start(Api)

    on_exit(fn ->
      capture_log(fn ->
        :mnesia.stop()
        :mnesia.delete_schema([node()])
      end)
    end)
  end

  describe "opening accounts" do
    test "an account can be opened" do
      assert %{identifier: "account_one"} =
               Account
               |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
               |> Api.create!()
    end

    test "you cannot open duplicate accounts" do
      assert %{identifier: "account_one"} =
               Account
               |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
               |> Api.create!()

      assert_raise Ash.Error.Invalid, ~r/identifier: has already been taken/, fn ->
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Api.create!()
      end
    end
  end

  describe "transfers" do
    test "with no transfers, balance is 0" do
      account_balance =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Api.create!()
        |> Api.load!(:balance_as_of)
        |> Map.get(:balance_as_of)

      assert Money.equal?(account_balance, Money.new!(:USD, 0))
    end

    test "transfers between accounts update the balance accordingly" do
      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Api.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Api.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id
      })
      |> Api.create!()

      Application.put_env(:foo, :bar, true)

      assert Money.equal?(
               Api.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -20)
             )

      # assert Money.equal?(
      #          Api.load!(account_two, :balance_as_of).balance_as_of,
      #          Money.new!(:USD, 20)
      #        )
    end

    test "balances can be validated" do
      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_one",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Api.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Api.create!()

      assert_raise Ash.Error.Invalid, ~r/balance cannot be negative/, fn ->
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_one.id,
          to_account_id: account_two.id
        })
        |> Api.create!()
      end
    end

    test "balances are validated for each future balance" do
      now = DateTime.utc_now()

      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_one",
          currency: "USD"
        })
        |> Api.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_two",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Api.create!()

      account_three =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_three",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Api.create!()

      account_four =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_four",
          currency: "USD",
          allow_zero_balance: false,
          timestamp: now
        })
        |> Api.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id,
        timestamp: DateTime.add(now, 2, :minute)
      })
      |> Api.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_two.id,
        to_account_id: account_three.id,
        timestamp: DateTime.add(now, 3, :minute)
      })
      |> Api.create!()

      assert_raise Ash.Error.Invalid, ~r/balance cannot be negative/, fn ->
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_two.id,
          to_account_id: account_four.id,
          timestamp: DateTime.add(now, 1, :minute)
        })
        |> Api.create!()
      end
    end
  end
end
