defmodule GatewayVPNService.Mixfile do
  use Mix.Project

  def project do
    [app: :gateway_vpn_service,
     version: "0.0.1",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :porcelain, :exredis], mod: {GatewayVPNService,[]} ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:gateway, in_umbrella: true},
      {:exredis, ">= 0.1.1"},
      {:poolboy,  github: "devinus/poolboy" },
      {:logger_file_backend, github: "onkel-dirtus/logger_file_backend" }
    ]
  end
end
