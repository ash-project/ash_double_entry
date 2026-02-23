# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.Test.Repo do
  @moduledoc false
  use AshPostgres.Repo, otp_app: :ash_double_entry

  def init(_, config) do
    {:ok,
     Keyword.merge(config,
       snapshots_path: "test/support/snapshots",
       migrations_path: "test/support/migrations"
     )}
  end

  def all_tenants, do: []

  @doc false
  def installed_extensions,
    do: ["ash-functions", "uuid-ossp", "citext", AshMoney.AshPostgresExtension]

  @doc false
  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end
