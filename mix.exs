defmodule AshDoubleEntry.MixProject do
  use Mix.Project

  @version "0.1.1"
  @description """
  A customizable double entry bookkeeping system backed by Ash resources.
  """

  def project do
    [
      app: :ash_double_entry,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      description: @description,
      aliases: aliases(),
      deps: deps(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/ash-project/ash_double_entry",
      homepage_url: "https://github.com/ash-project/ash_double_entry",
      consolidate_protocols: Mix.env() != :test
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: :ash_double_entry,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
        CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/ash-project/ash_double_entry"
      }
    ]
  end

  defp aliases do
    [
      sobelow: "sobelow --skip",
      credo: "credo --strict",
      docs: ["docs", "ash.replace_doc_links"],
      "spark.formatter":
        "spark.formatter --extensions AshDoubleEntry.Account,AshDoubleEntry.Balance,AshDoubleEntry.Transfer"
    ]
  end

  defp extras() do
    "documentation/**/*.md"
    |> Path.wildcard()
    |> Enum.map(fn path ->
      title =
        path
        |> Path.basename(".md")
        |> String.split(~r/[-_]/)
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")
        |> case do
          "F A Q" ->
            "FAQ"

          other ->
            other
        end

      {String.to_atom(path),
       [
         title: title
       ]}
    end)
  end

  defp groups_for_extras() do
    "documentation/*"
    |> Path.wildcard()
    |> Enum.map(fn folder ->
      name =
        folder
        |> Path.basename()
        |> String.split(~r/[-_]/)
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")

      {name, folder |> Path.join("**") |> Path.wildcard()}
    end)
  end

  defp docs do
    [
      main: "get-started-with-double-entry",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      extras: extras(),
      spark: [
        extensions: [
          %{
            module: AshDoubleEntry.Balance,
            name: "AshDoubleEntry.Balance",
            target: "Ash.Resource",
            type: "Extension"
          },
          %{
            module: AshDoubleEntry.Transfer,
            name: "AshDoubleEntry.Transfer",
            target: "Ash.Resource",
            type: "Extension"
          },
          %{
            module: AshDoubleEntry.Balance,
            name: "AshDoubleEntry.Balance",
            target: "Ash.Resource",
            type: "Extension"
          }
        ]
      ],
      groups_for_extras: groups_for_extras(),
      groups_for_modules: [
        AshDoubleEntry: ~r/AshDoubleEntry.*/,
        Internals: ~r/.*/
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, ash_version("~> 2.14")},
      {:git_ops, "~> 2.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.22", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: [:dev, :test]}
    ]
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil ->
        default_version

      "local" ->
        [path: "../ash"]

      "main" ->
        [git: "https://github.com/ash-project/ash.git"]

      version when is_binary(version) ->
        "~> #{version}"

      version ->
        version
    end
  end
end
