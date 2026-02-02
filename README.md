<!--
SPDX-FileCopyrightText: 2020 Zach Daniel

SPDX-License-Identifier: MIT
-->

![Logo](https://github.com/ash-project/ash/blob/main/logos/cropped-for-header-black-text.png?raw=true#gh-light-mode-only)
![Logo](https://github.com/ash-project/ash/blob/main/logos/cropped-for-header-white-text.png?raw=true#gh-dark-mode-only)

![Elixir CI](https://github.com/ash-project/ash_double_entry/workflows/CI/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/ash_double_entry.svg)](https://hex.pm/packages/ash_double_entry)
[![Hexdocs badge](https://img.shields.io/badge/docs-hexdocs-purple)](https://hexdocs.pm/ash_double_entry)
[![REUSE status](https://api.reuse.software/badge/github.com/ash-project/ash_double_entry)](https://api.reuse.software/info/github.com/ash-project/ash_double_entry)

# AshDoubleEntry

Welcome! This is the extension for building a double entry accounting system in [Ash](https://hexdocs.pm/ash). This extension provides the basic building blocks for you to extend as necessary.

## Double Entry Accounting

Double entry accounting is a fundamental accounting principle that ensures every financial transaction is recorded in at least two accounts. Each transaction records a **debit** (money going out) and **credit** (money coming in), where total debits must equal total credits. This dual-record system allows you to detect errors and ensures that books always balance.

AshDoubleEntry implements double entry accounting through three core resources:

1. **Account**, which represents accounts in your ledger (such as bank accounts, revenue accounts, expense accounts, etc.)
2. **Transfer**, which represents transactions between accounts, always linking a `from_account` and `to_account` with an amount
3. **Balance**, which tracks the balance of each account at the point of each transfer for recordkeeping

When you create a balance transfer, the system creates entries for both the credit and debit accounts and updates all future balances to reflect the transaction.

## Why a Separate Repository?

As double entry accounting is a specialized financial feature that is only necessary for certain Ash applications, keeping it as a separate repository allows the main framework to remain focused on core functionality. This also allows the implementation of double entry to evolve separately from the core Ash framework. **Ash  applications that don't need double entry accounting can safely ignore this.**

This follows the same pattern as other Ash extensions like [AshMoney](https://hexdocs.pm/ash_money) and [AshAuthentication](https://hexdocs.pm/ash_authentication), which are also maintained as separate packages.

## Tutorials

- [Getting Started with AshDoubleEntry](documentation/tutorials/getting-started-with-ash-double-entry.md)

## Reference

- [AshDoubleEntry.Account DSL](documentation/dsls/DSL-AshDoubleEntry.Account.md)
- [AshDoubleEntry.Transfer DSL](documentation/dsls/DSL-AshDoubleEntry.Transfer.md)
- [AshDoubleEntry.Balance DSL](documentation/dsls/DSL-AshDoubleEntry.Balance.md)
