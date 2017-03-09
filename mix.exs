defmodule UeberauthEDM.Mixfile do
  use Mix.Project

  @version "0.0.1"
  @url "https://github.com/mytardis/ueberauth_edm"

  def project do
    [app: :ueberauth_edm,
     version: @version,
     name: "Ueberauth EDM Strategy",
     package: package(),
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: @url,
     homepage_url: @url,
     description: description(),
     deps: deps(),
     docs: docs()]
  end

  def application do
    [applications: [:logger, :oauth2, :ueberauth, :poison, :httpoison]]
  end

  defp deps do
    [{:ueberauth, "~> 0.2"},
     {:oauth2, "=> 0.8 and < 1.0"},
     {:httpoison, "~> 0.9.0"},
     {:poison, "~> 2.0"},
     {:ex_doc, "~> 0.1", only: :dev},
     {:earmark, ">= 0.0.0", only: :dev}]
  end

  defp docs do
    [extras: ["README.md", "CONTRIBUTING.md"]]
  end

  defp description do
    "An Uberauth strategy for EDM authentication."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Jason Rigby"],
     licenses: ["MIT"],
     links: %{"GitHub": @url}]
  end
end
