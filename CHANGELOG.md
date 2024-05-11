# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v1.0.1](https://github.com/ash-project/ash_double_entry/compare/v1.0.0...v1.0.1) (2024-05-11)

### Bug Fixes:

- [AshDoubleEntry.Balance] use `a + -b`, instead of `a - b` (which is not supported by our AshPostgresExtension)

## [v1.0.0](https://github.com/ash-project/ash_double_entry/compare/v1.0.0-rc.1...v1.0.0) (2024-05-10)

## [v1.0.0-rc.1](https://github.com/ash-project/ash_double_entry/compare/v1.0.0-rc.0...v1.0.0-rc.1) (2024-04-29)

### Improvements:

- update to support new atomics & bulk actions

## [v1.0.0-rc.0](https://github.com/ash-project/ash_double_entry/compare/v0.2.4...v1.0.0-rc.0) (2024-04-01)

### Breaking Changes:

- update to Ash 3.0

### Bug Fixes:

- correct amount_delta calculation from destorying (#13)

## [v0.2.4](https://github.com/ash-project/ash_double_entry/compare/v0.2.3...v0.2.4) (2024-02-14)

### Bug Fixes:

- properly update future balances from destroys

- incorrect balance when adding transfer later (#12)

## [v0.2.3](https://github.com/ash-project/ash_double_entry/compare/v0.2.2...v0.2.3) (2023-12-23)

### Bug Fixes:

- make expression pure

### Improvements:

- support updating transfer's amount (#8)

## [v0.2.2](https://github.com/ash-project/ash_double_entry/compare/v0.2.1...v0.2.2) (2023-12-10)

### Improvements:

- support updating transfers, but not important fields

## [v0.2.1](https://github.com/ash-project/ash_double_entry/compare/v0.2.0...v0.2.1) (2023-12-10)

### Bug Fixes:

- use Money..add! For correct return

- properly set context on account read in balance verification

### Improvements:

- support destroying transfers

- set `context_to_opts` when constructing the query

## [v0.2.0](https://github.com/ash-project/ash_double_entry/compare/v0.1.2...v0.2.0) (2023-12-06)

### Features:

- use AshMoney

### Bug Fixes:

- ensure transformers run before `BelongsToAttribute`

- update ash for fix

### Improvements:

- migrate to AshMoney

- update ash

## [v0.1.2](https://github.com/ash-project/ash_double_entry/compare/v0.1.1...v0.1.2) (2023-08-19)

- Documentation updates & AshHq indexing fixes

## [v0.1.1](https://github.com/ash-project/ash_double_entry/compare/v0.1.0...v0.1.1) (2023-08-19)

### Bug Fixes:

- properly calculate balance_as_of_ulid when transfer is to or from account

## [v0.1.0](https://github.com/ash-project/ash_double_entry/compare/v0.1.0...v0.1.0) (2023-08-19)

### Bug Fixes:

- create balances after transfer is created

- don't require pagination

### Improvements:

- add CI & check commands

- wrap up initial implementaiton, add guides

- initial test suite & functionality
