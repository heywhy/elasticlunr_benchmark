defmodule Elasticlunr.Benchmark.MixProject do
  use Mix.Project

  def project do
    [
      app: :elasticlunr_benchmark,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      xref: [exclude: [EEx]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Elasticlunr.Benchmark.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.0"},
      {:benchee_html, "~> 1.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:elasticlunr, "~> 0.6", optional: true},
      {:flake_id, "~> 0.1"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.3"}
    ]
  end

  defp aliases do
    [
      test: ~w[format credo test]
    ]
  end
end
