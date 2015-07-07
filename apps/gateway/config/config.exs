# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
config :porcelain, :goon_driver_path, "/usr/bin/goon"
config :gateway, 
    gateway_api_url: "https://api.gateway.evercam.io:443/v1",
    data_folder: ".evercam",
    mac_file: "mac_address",
    token_file: "token",
    config_file: "config",
    x509_cert_file: "ether_x509_cert",
    private_key_file: "ether_private_key",
    m2m_secret_file: "m2m_secret",
    vpn_account_name: "evercam_gateway",
    exclude_interfaces: ['lo','vpn_ether'],
    vpncmd_path: "/opt/vpn/vpncmd"

config :logger,
  backends: [{LoggerFileBackend, :info},
             {LoggerFileBackend, :error}]

config :logger, :info,
  path: "gateway-info.log",
  level: :info

config :logger, :error,
  path: "gateway-error.log",
  level: :error
