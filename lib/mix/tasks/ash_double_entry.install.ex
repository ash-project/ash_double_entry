# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AshDoubleEntry.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs AshDoubleEntry"
  end

  def example do
    "mix ash_double_entry.install --example arg"
  end

  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshDoubleEntry.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :ash,
        # dependencies to add
        adds_deps: [],
        # dependencies to add and call their associated installers, if they exist
        installs: [
          {:ash_money, "~> 0.2"}
        ],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [
          repo: :string
        ],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [r: :repo],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      # Do your work here and return an updated igniter
      prefix = Igniter.Project.Module.module_name_prefix(igniter)

      account = Module.concat([prefix, "Ledger", "Account"])
      transfer = Module.concat([prefix, "Ledger", "Transfer"])
      balance = Module.concat([prefix, "Ledger", "Balance"])
      domain = Module.concat([prefix, "Ledger"])

      data_layer =
        cond do
          Igniter.Project.Deps.has_dep?(igniter, :ash_postgres) ->
            AshPostgres.DataLayer

          Igniter.Project.Deps.has_dep?(igniter, :ash_sqlite) ->
            AshSqlite.DataLayer

          true ->
            nil
        end

      if data_layer do
        {igniter, repo} = Igniter.Libs.Ecto.select_repo(igniter)

        if repo do
          igniter
          |> Igniter.compose_task("ash.gen.domain", [inspect(domain), "--ignore-if-exists"])
          |> Igniter.Project.Formatter.import_dep(:ash_double_entry)
          |> Spark.Igniter.prepend_to_section_order(:"Ash.Resource", [
            :account,
            :balance,
            :transfer
          ])
          |> Igniter.Project.Config.configure(
            "config.exs",
            :ash,
            [:known_types],
            [AshMoney.Types.Money],
            updater: fn zipper ->
              Igniter.Code.List.append_new_to_list(zipper, AshMoney.Types.Money)
            end
          )
          |> Igniter.Project.Config.configure(
            "config.exs",
            :ash,
            [:custom_types, :money],
            AshMoney.Types.Money
          )
          |> create_accounts(transfer, account, balance, data_layer, repo, domain)
          |> create_balances(transfer, account, balance, data_layer, repo, domain)
          |> create_transfers(transfer, account, balance, data_layer, repo, domain)
          |> Ash.Domain.Igniter.add_resource_reference(domain, account)
          |> Ash.Domain.Igniter.add_resource_reference(domain, balance)
          |> Ash.Domain.Igniter.add_resource_reference(domain, transfer)
          |> Ash.Igniter.codegen("add_ledger")
        else
          Igniter.add_warning(igniter, """
          No repo found, or no repo was selected. Please ensure that `ash_postgres` or `ash_sqlite`
          are installed, and you have a repo available, then rerun this installer with:

              mix igniter.install ash_double_entry
          """)
        end
      else
        Igniter.add_warning(igniter, """
        Could not install `ash_double_entry` without `ash_postgres` or `ash_sqlite`.
        Please install one of the two and rerun the installer with:

            mix igniter.install ash_double_entry
        """)
      end
    end

    defp create_balances(igniter, transfer, account, balance, data_layer, repo, domain) do
      {balance_attr, can_add_money} =
        if data_layer == AshPostgres.DataLayer do
          {"""
           attribute :balance, :money do
             constraints storage_type: :money_with_currency
           end
           """, true}
        else
          {"""
           attribute :balance, :money
           """, false}
        end

      Igniter.Project.Module.create_module(igniter, balance, """
      use Ash.Resource,
        domain: #{domain},
        data_layer: #{inspect(data_layer)},
        extensions: [AshDoubleEntry.Balance]

      #{data_layer_dsl_block(data_layer)} do
        table "ledger_balances"
        repo #{inspect(repo)}
      end

      balance do
        transfer_resource #{inspect(transfer)}
        account_resource #{inspect(account)}
      end

      actions do
        defaults [:read]

        create :upsert_balance do
          accept [:balance, :account_id, :transfer_id]
          upsert? true
          upsert_identity :unique_references
        end

        update :adjust_balance do
          argument :from_account_id, :uuid_v7, allow_nil?: false
          argument :to_account_id, :uuid_v7, allow_nil?: false
          argument :delta, :money, allow_nil?: false
          argument :transfer_id, AshDoubleEntry.ULID, allow_nil?: false

          change filter expr(account_id in [^arg(:from_account_id), ^arg(:to_account_id)] and transfer_id > ^arg(:transfer_id))
          change {AshDoubleEntry.Balance.Changes.AdjustBalance, can_add_money?: #{can_add_money}}
        end
      end

      attributes do
        uuid_v7_primary_key :id

        #{balance_attr}
      end

      identities do
        identity :unique_references, [:account_id, :transfer_id]
      end

      relationships do
        belongs_to :transfer, #{inspect(transfer)} do
          attribute_type AshDoubleEntry.ULID
          allow_nil? false
          attribute_writable? true
        end

        belongs_to :account, #{inspect(account)} do
          allow_nil? false
          attribute_writable? true
        end
      end
      """)
    end

    defp create_accounts(igniter, transfer, account, balance, data_layer, repo, domain) do
      Igniter.Project.Module.create_module(igniter, account, """
      use Ash.Resource,
        domain: #{domain},
        data_layer: #{inspect(data_layer)},
        extensions: [AshDoubleEntry.Account]

      #{data_layer_dsl_block(data_layer)} do
        table "ledger_accounts"
        repo #{inspect(repo)}
      end

      account do
        # configure the other resources it will interact with
        transfer_resource #{inspect(transfer)}
        balance_resource #{inspect(balance)}
      end

      attributes do
        uuid_v7_primary_key :id

        attribute :identifier, :string do
          allow_nil? false
        end

        attribute :currency, :string do
          allow_nil? false
        end

        timestamps()
      end

      account do
        transfer_resource #{inspect(transfer)}
        balance_resource #{inspect(balance)}
      end

      identities do
        identity :unique_identifier, [:identifier]
      end

      actions do
        defaults [:read]

        create :open do
          accept [:identifier, :currency]
        end

        read :lock_accounts do
          # Used to lock accounts while doing ledger operations
          prepare {AshDoubleEntry.Account.Preparations.LockForUpdate, []}
        end
      end

      relationships do
        has_many :balances, #{inspect(balance)} do
          destination_attribute :account_id
        end
      end

      calculations do
        calculate :balance_as_of_ulid, :money do
          calculation {AshDoubleEntry.Account.Calculations.BalanceAsOfUlid, resource: __MODULE__}

          argument :ulid, AshDoubleEntry.ULID do
            allow_nil? false
            allow_expr? true
          end
        end

        calculate :balance_as_of, :money do
          calculation {AshDoubleEntry.Account.Calculations.BalanceAsOf, resource: __MODULE__}

          argument :timestamp, :utc_datetime_usec do
            allow_nil? false
            allow_expr? true
            default &DateTime.utc_now/0
          end
        end
      end
      """)
    end

    defp create_transfers(igniter, transfer, account, balance, data_layer, repo, domain) do
      Igniter.Project.Module.create_module(igniter, transfer, """
      use Ash.Resource,
        domain: #{domain},
        data_layer: #{inspect(data_layer)},
        extensions: [AshDoubleEntry.Transfer]

      #{data_layer_dsl_block(data_layer)} do
        table "ledger_transfers"
        repo #{inspect(repo)}
      end

      transfer do
        account_resource #{inspect(account)}
        balance_resource #{inspect(balance)}
      end

      actions do
        defaults [:read]

        create :transfer do
          accept [:amount, :timestamp, :from_account_id, :to_account_id]
        end
      end

      attributes do
        attribute :id, AshDoubleEntry.ULID do
          primary_key? true
          allow_nil? false
          default &AshDoubleEntry.ULID.generate/0
        end

        attribute :amount, :money do
          allow_nil? false
        end

        timestamps()
      end

      relationships do
        belongs_to :from_account, #{inspect(account)} do
          attribute_writable? true
        end

        belongs_to :to_account, #{inspect(account)} do
          attribute_writable? true
        end

        has_many :balances, #{inspect(balance)}
      end
      """)
    end

    defp data_layer_dsl_block(AshPostgres.DataLayer) do
      "postgres"
    end

    defp data_layer_dsl_block(_) do
      "sqlite"
    end
  end
else
  defmodule Mix.Tasks.AshDoubleEntry.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'ash_double_entry.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
