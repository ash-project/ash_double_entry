defmodule AshDoubleEntry.MixProject do
  use Mix.Project

  @version "1.0.11"
  @description """
  A customizable double entry bookkeeping system backed by Ash resources.
  """

  def project do
    [
      app: :ash_double_entry,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      description: @description,
      dialyzer: [plt_add_apps: [:mix]],
      aliases: aliases(),
      deps: deps(),
      package: package(),
      docs: &docs/0,
      source_url: "https://github.com/ash-project/ash_double_entry",
      homepage_url: "https://github.com/ash-project/ash_double_entry",
      consolidate_protocols: Mix.env() != :test
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: :ash_double_entry,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
        CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/ash-project/ash_double_entry"
      }
    ]
  end

  defp aliases do
    [
      sobelow: "sobelow --skip",
      credo: "credo --strict",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
      ],
      "spark.formatter":
        "spark.formatter --extensions AshDoubleEntry.Account,AshDoubleEntry.Balance,AshDoubleEntry.Transfer",
      "spark.cheat_sheets":
        "spark.cheat_sheets --extensions AshDoubleEntry.Account,AshDoubleEntry.Balance,AshDoubleEntry.Transfer",
      "spark.cheat_sheets_in_search":
        "spark.cheat_sheets_in_search --extensions AshDoubleEntry.Account,AshDoubleEntry.Balance,AshDoubleEntry.Transfer"
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      before_closing_head_tag: fn type ->
        if type == :html do
          """
          <script>
            if (location.hostname === "hexdocs.pm") {
              var script = document.createElement("script");
              script.src = "https://plausible.io/js/script.js";
              script.setAttribute("defer", "defer")
              script.setAttribute("data-domain", "ashhexdocs")
              document.head.appendChild(script);
            }
          </script>
          """
        end
      end,
      extras: [
        {"README.md", title: "Home"},
        {"documentation/tutorials/getting-started-with-ash-double-entry.md",
         title: "Get Started"},
        {"documentation/dsls/DSL-AshDoubleEntry.Account.md",
         search_data: Spark.Docs.search_data_for(AshDoubleEntry.Account)},
        {"documentation/dsls/DSL-AshDoubleEntry.Balance.md",
         search_data: Spark.Docs.search_data_for(AshDoubleEntry.Balance)},
        {"documentation/dsls/DSL-AshDoubleEntry.Transfer.md",
         search_data: Spark.Docs.search_data_for(AshDoubleEntry.Transfer)},
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Tutorials: ~r'documentation/tutorials',
        "How To": ~r'documentation/how_to',
        Topics: ~r'documentation/topics',
        DSLs: ~r'documentation/dsls',
        "About AshDoubleEntry": [
          "CHANGELOG.md"
        ]
      ],
      groups_for_modules: [
        Introspection: [
          AshDoubleEntry.Account.Info,
          AshDoubleEntry.Balance.Info,
          AshDoubleEntry.Transfer.Info
        ],
        Entities: [
          AshDoubleEntry.Account,
          AshDoubleEntry.Balance,
          AshDoubleEntry.Transfer
        ],
        Types: [
          AshDoubleEntry.ULID
        ],
        AshDoubleEntry: ~r/AshDoubleEntry.*/
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, ash_version("~> 3.0")},
      {:ash_money, "~> 0.1"},
      {:ex_money_sql, "~> 1.10"},
      # dev/test dependencies
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:git_ops, "~> 2.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.37-rc", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil ->
        default_version

      "local" ->
        [path: "../ash", override: true]

      "main" ->
        [git: "https://github.com/ash-project/ash.git", override: true]

      version when is_binary(version) ->
        "~> #{version}"

      version ->
        version
    end
  end
end
