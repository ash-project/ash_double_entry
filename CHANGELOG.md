# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.2.2](https://github.com/ash-project/ash_double_entry/compare/v0.2.1...v0.2.2) (2023-12-10)




### Improvements:

* support updating transfers, but not important fields

## [v0.2.1](https://github.com/ash-project/ash_double_entry/compare/v0.2.0...v0.2.1) (2023-12-10)




### Bug Fixes:

* use Money..add! For correct return

* properly set context on account read in balance verification

### Improvements:

* support destroying transfers

* set `context_to_opts` when constructing the query

## [v0.2.0](https://github.com/ash-project/ash_double_entry/compare/v0.1.2...v0.2.0) (2023-12-06)




### Features:

* use AshMoney

### Bug Fixes:

* ensure transformers run before `BelongsToAttribute`

* update ash for fix

### Improvements:

* migrate to AshMoney

* update ash

## [v0.1.2](https://github.com/ash-project/ash_double_entry/compare/v0.1.1...v0.1.2) (2023-08-19)

- Documentation updates & AshHq indexing fixes


## [v0.1.1](https://github.com/ash-project/ash_double_entry/compare/v0.1.0...v0.1.1) (2023-08-19)




### Bug Fixes:

* properly calculate balance_as_of_ulid when transfer is to or from account

## [v0.1.0](https://github.com/ash-project/ash_double_entry/compare/v0.1.0...v0.1.0) (2023-08-19)




### Bug Fixes:

* create balances after transfer is created

* don't require pagination

### Improvements:

* add CI & check commands

* wrap up initial implementaiton, add guides

* initial test suite & functionality
