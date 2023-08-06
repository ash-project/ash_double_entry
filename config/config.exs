import Config
config :ash, :use_all_identities_in_manage_relationship?, false

if config_env() == :test do
  config :ash, :validate_api_resource_inclusion?, false
  config :ash, :validate_api_config_inclusion?, false
end
