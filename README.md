# AshDoubleEntry

An extensible double entry system built using [Ash](ash-hq.org) resources.

See the [getting started guide](https://hexdocs.pm/ash_double_entry/get-started-with-double-entry.html) to
setup the project!

## Installation

The package can be installed by adding `ash_double_entry` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_double_entry, "~> 0.2.1"}
  ]
end
```

# Upgrading from 0.1 to 0.2

This is a breaking change, that changes from using a currency & decimal amount to using `ash_money`. There is no way to configure it to use the old behavior, as maintaining both is not reasonable.