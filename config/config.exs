import Config

if Mix.env() == :dev do
  config :git_ops,
    mix_project: AshDoubleEntry.MixProject,
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/ash-project/ash_double_entry",
    # Instructs the tool to manage your mix version in your `mix.exs` file
    # See below for more information
    manage_mix_version?: true,
    # Instructs the tool to manage the version in your README.md
    # Pass in `true` to use `"README.md"` or a string to customize
    manage_readme_version: ["README.md"],
    version_tag_prefix: "v"
end

if config_env() == :test do
  config :ash, :validate_domain_resource_inclusion?, false
  config :ash, :validate_domain_config_inclusion?, false
  config :ash, :disable_async?, true
  config :ex_money, default_cldr_backend: AshMoney.Cldr

  config :ash_double_entry,
    ecto_repos: [AshDoubleEntry.Test.Repo],
    ash_domains: [AshDoubleEntry.Test.Domain]

  config :ash_double_entry, AshDoubleEntry.Test.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "ash_double_entry_test#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10
end

config :ash, :known_types, [AshMoney.Types.Money]
config :logger, level: :error

config :spark, :formatter,
  remove_parens?: true,
  "Ash.Resource": []
