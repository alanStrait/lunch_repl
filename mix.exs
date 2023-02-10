defmodule DineOutside.MixProject do
  use Mix.Project

  def project do
    [
      app: :lunch_repl,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DineOutside.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:haversine, "~> 0.1.0"},
      {:nimble_csv, "~> 1.2.0"}
    ]
  end
end
