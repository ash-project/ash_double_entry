# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshMoney.Cldr do
  @moduledoc false
  use Cldr,
    locales: ["en"],
    default_locale: "en"
end
