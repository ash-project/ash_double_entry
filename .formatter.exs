# Used by "mix format"
spark_locals_without_parens = [
  account_resource: 1,
  balance_resource: 1,
  open_action_accept: 1,
  pre_check_identities_with: 1,
  transfer_resource: 1
]

[
  locals_without_parens: spark_locals_without_parens,
  import_deps: [:ash],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
