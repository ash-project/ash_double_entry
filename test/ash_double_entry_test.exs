defmodule AshDoubleEntryTest do
  use ExUnit.Case
  require Ash.Query

  defmodule RequiresPositiveBalance do
    use Ash.Resource.Validation

    def validate(changeset, _, _) do
      account_id = Ash.Changeset.get_attribute(changeset, :account_id)

      if is_nil(account_id) do
        :ok
      else
        account = Ash.get!(AshDoubleEntryTest.Account, account_id, authorize?: false)

        if account.allow_zero_balance do
          {:error, "Account must require positive balance"}
        else
          :ok
        end
      end
    end

    def atomic(_changeset, _, _) do
      {:atomic, [:account], expr(account.allow_zero_balance == false),
       expr(
         error(Ash.Error.Changes.InvalidRelationship,
           relationship: :account,
           message: "Account must require positive balance"
         )
       )}
    end
  end

  defmodule Account do
    use Ash.Resource,
      domain: AshDoubleEntryTest.Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshDoubleEntry.Account]

    ets do
      private? true
    end

    account do
      pre_check_identities_with AshDoubleEntryTest.Domain
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
      domain: AshDoubleEntryTest.Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshDoubleEntry.Transfer]

    ets do
      private? true
    end

    transfer do
      account_resource Account
      balance_resource AshDoubleEntryTest.Balance
    end

    actions do
      defaults [:destroy, update: [:amount]]
    end
  end

  defmodule Balance do
    use Ash.Resource,
      domain: AshDoubleEntryTest.Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshDoubleEntry.Balance]

    ets do
      private? true
    end

    balance do
      pre_check_identities_with AshDoubleEntryTest.Domain
      transfer_resource Transfer
      account_resource Account
    end

    actions do
      defaults [:destroy]
    end

    validations do
      validate compare(:balance, greater_than_or_equal_to: 0),
        where: [RequiresPositiveBalance],
        message: "balance cannot be negative"
    end
  end

  defmodule Domain do
    use Ash.Domain

    resources do
      resource Account
      resource Transfer
      resource Balance
    end
  end

  describe "opening accounts" do
    test "an account can be opened" do
      assert %{identifier: "account_one"} =
               Account
               |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
               |> Ash.create!()
    end

    test "you cannot open duplicate accounts" do
      assert %{identifier: "account_one"} =
               Account
               |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
               |> Ash.create!()

      assert_raise Ash.Error.Invalid, ~r/identifier: has already been taken/, fn ->
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()
      end
    end
  end

  describe "transfers" do
    test "with no transfers, balance is 0" do
      account_balance =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()
        |> Ash.load!(:balance_as_of)
        |> Map.get(:balance_as_of)

      assert Money.equal?(account_balance, Money.new!(:USD, 0))
    end

    test "transfers between accounts update the balance accordingly" do
      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id
      })
      |> Ash.create!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -20)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 20)
             )
    end

    test "destroying transfers update the balances accordingly" do
      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id
      })
      |> Ash.create!()
      |> Ash.Changeset.for_destroy(:destroy)
      |> Ash.destroy!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )
    end

    test "updating transfer's amount update the balances accordingly" do
      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id
      })
      |> Ash.create!()
      |> Ash.Changeset.for_update(:update, %{amount: Money.new!(:USD, 10)})
      |> Ash.update!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -10)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 10)
             )
    end

    test "adding transfer update the balances accordingly" do
      now = DateTime.utc_now()

      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id,
        timestamp: now
      })
      |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_two.id,
        to_account_id: account_one.id,
        timestamp: DateTime.add(now, -2, :minute)
      })
      |> Ash.create!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )
    end

    test "destroying a transfer update the balances accordingly" do
      now = DateTime.utc_now()

      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_one", currency: "USD"})
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Ash.create!()

      transfer_1 =
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_one.id,
          to_account_id: account_two.id,
          timestamp: now
        })
        |> Ash.create!()

      transfer_2 =
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_two.id,
          to_account_id: account_one.id,
          timestamp: DateTime.add(now, -2, :minute)
        })
        |> Ash.create!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )

      transfer_2 |> Ash.destroy!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -20)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 20)
             )

      transfer_1 |> Ash.destroy!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 0)
             )
    end

    test "balances can be validated" do
      account_one =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_one",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{identifier: "account_two", currency: "USD"})
        |> Ash.create!()

      assert_raise Ash.Error.Invalid, ~r/balance cannot be negative/, fn ->
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_one.id,
          to_account_id: account_two.id
        })
        |> Ash.create!()
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
        |> Ash.create!()

      account_two =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_two",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Ash.create!()

      account_three =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_three",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Ash.create!()

      account_four =
        Account
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_four",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_one.id,
        to_account_id: account_two.id,
        timestamp: DateTime.add(now, 2, :minute)
      })
      |> Ash.create!()

      Transfer
      |> Ash.Changeset.for_create(:transfer, %{
        amount: Money.new!(:USD, 20),
        from_account_id: account_two.id,
        to_account_id: account_three.id,
        timestamp: DateTime.add(now, 3, :minute)
      })
      |> Ash.create!()

      assert_raise Ash.Error.Invalid, ~r/balance cannot be negative/, fn ->
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_two.id,
          to_account_id: account_four.id,
          timestamp: DateTime.add(now, 1, :minute)
        })
        |> Ash.create!()
      end
    end
  end
end
