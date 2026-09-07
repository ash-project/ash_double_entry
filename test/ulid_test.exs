# SPDX-FileCopyrightText: 2023 ash_double_entry contributors <https://github.com/ash-project/ash_double_entry/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshDoubleEntry.ULIDTest do
  use ExUnit.Case, async: true

  alias AshDoubleEntry.ULID

  test "non-canonical first characters are rejected, so each ULID has one spelling" do
    canonical = ULID.generate(0)
    tail = binary_part(canonical, 1, 25)

    assert {:ok, ^canonical} = ULID.cast_input(canonical, [])

    # The first Crockford character encodes only 3 bits, so 0, 8, G and R all
    # decode to the same low 3 bits. Only the canonical `0` spelling may be
    # accepted; the others used to alias to the same row.
    for bad <- ["8", "G", "R"] do
      id = bad <> tail
      assert :error = ULID.cast_input(id, []), "cast_input should reject #{id}"
      assert :error = ULID.dump_to_native(id, []), "dump_to_native should reject #{id}"
    end
  end

  test "an accepted id round-trips to its own canonical spelling" do
    canonical = ULID.generate(0)
    {:ok, native} = ULID.dump_to_native(canonical, [])
    assert {:ok, ^canonical} = ULID.cast_stored(native, [])
  end
end
