# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v1.0.12](https://github.com/ash-project/ash_double_entry/compare/v1.0.11...v1.0.12) (2025-02-24)




### Bug Fixes:

* don't include VerifyTransfer in the codegen

## [v1.0.11](https://github.com/ash-project/ash_double_entry/compare/v1.0.10...v1.0.11) (2025-02-24)




### Bug Fixes:

* use `utc_datetime_usec` in balance_as_of in installer

## [v1.0.10](https://github.com/ash-project/ash_double_entry/compare/v1.0.9...v1.0.10) (2025-01-26)




### Bug Fixes:

* use correct module reference in installer(#82)

* Use correct argument name for :balance_as_of calc in installer

## [v1.0.9](https://github.com/ash-project/ash_double_entry/compare/v1.0.8...v1.0.9) (2025-01-13)




### Improvements:

* proper reference for section order config in installer

## [v1.0.8](https://github.com/ash-project/ash_double_entry/compare/v1.0.7...v1.0.8) (2025-01-13)




### Improvements:

* add igniter installer

## [v1.0.7](https://github.com/ash-project/ash_double_entry/compare/v1.0.6...v1.0.7) (2025-01-06)




### Bug Fixes:

* add `dump_to_embedded` logic for `AshDoubleEntry.ULID`

* do negation manually instead of in expression

## [v1.0.6](https://github.com/ash-project/ash_double_entry/compare/v1.0.5...v1.0.6) (2024-08-03)




### Bug Fixes:

* properly set authorize option when updating transfers

## [v1.0.5](https://github.com/ash-project/ash_double_entry/compare/v1.0.4...v1.0.5) (2024-08-03)




### Bug Fixes:

* set `authorize?` properly when creating balances

## [v1.0.4](https://github.com/ash-project/ash_double_entry/compare/v1.0.3...v1.0.4) (2024-07-03)




### Bug Fixes:

* better validations around atomics

### Improvements:

* allow skipping balance updates on request

* don't destroy balances by default

## [v1.0.3](https://github.com/ash-project/ash_double_entry/compare/v1.0.2...v1.0.3) (2024-06-23)




### Bug Fixes:

* set a default for `create_accept`

### Improvements:

* use a guaranteed-last ulid for `balance_as_of` calculation

* accept attributes on transfer create

* don't use raising variations of resource calls

## [v1.0.2](https://github.com/ash-project/ash_double_entry/compare/v1.0.1...v1.0.2) (2024-06-18)

### Improvements:

- set context indicating that `ash_double_entry?` is performing an action

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
