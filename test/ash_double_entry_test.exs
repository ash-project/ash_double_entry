# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntryTest do
  use DataCase, async: false
  require Ash.Query

  alias AshDoubleEntry.Test.{Account, Transfer}

  setup do
    :ok
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
        |> Ash.Changeset.for_create(:open, %{
          identifier: "account_two",
          currency: "USD",
          allow_zero_balance: false
        })
        |> Ash.create!()

      transfer_1 =
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_one.id,
          to_account_id: account_two.id,
          timestamp: DateTime.add(now, -10, :minute)
        })
        |> Ash.create!()

      transfer_2 =
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_one.id,
          to_account_id: account_two.id,
          timestamp: DateTime.add(now, -9, :minute)
        })
        |> Ash.create!()

      transfer_3 =
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 20),
          from_account_id: account_one.id,
          to_account_id: account_two.id,
          timestamp: DateTime.add(now, -8, :minute)
        })
        |> Ash.create!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -60)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 60)
             )

      transfer_1 |> Ash.destroy!()

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -40)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 40)
             )

      transfer_4 =
        Transfer
        |> Ash.Changeset.for_create(:transfer, %{
          amount: Money.new!(:USD, 40),
          from_account_id: account_two.id,
          to_account_id: account_one.id,
          timestamp: DateTime.add(now, -7, :minute)
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

      assert_raise Ash.Error.Invalid, ~r/balance cannot be negative/, fn ->
        Ash.destroy!(transfer_2)
      end

      # we test atomic destroy here
      assert_raise Ash.Error.Invalid, ~r/balance cannot be negative/, fn ->
        Transfer
        |> Ash.Query.filter(id == ^transfer_3.id)
        |> Ash.bulk_destroy!(:destroy, %{}, return_errors?: true)
      end

      Ash.destroy!(transfer_4)

      assert Money.equal?(
               Ash.load!(account_one, :balance_as_of).balance_as_of,
               Money.new!(:USD, -40)
             )

      assert Money.equal?(
               Ash.load!(account_two, :balance_as_of).balance_as_of,
               Money.new!(:USD, 40)
             )

      Ash.destroy!(transfer_2)
      Ash.destroy!(transfer_3)

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
