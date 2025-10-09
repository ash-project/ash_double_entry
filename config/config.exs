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

config :ash, :allow_forbidden_field_for_relationships_by_default?, true
config :ash, :include_embedded_source_by_default?, false
config :ash, :show_keysets_for_all_actions?, false
config :ash, :default_page_type, :keyset
config :ash, :policies, no_filter_static_forbidden_reads?: false
config :ash, :keep_read_action_loads_when_loading?, false
config :ash, :default_actions_require_atomic?, true
config :ash, :read_action_after_action_hooks_in_order?, true
config :ash, :bulk_actions_default_to_errors?, true

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
    # sobelow_skip ["Config.Secrets"]
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
