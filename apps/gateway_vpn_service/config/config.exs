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
config :gateway_vpn_service,
       server_port: 6060,
       ssl_options: [{:certfile, "/var/apps/keys/vpn_service_ssl.crt"}, 
                     {:keyfile, "/var/apps/keys/vpn_service_ssl.key"},
                     {:ciphers, [{:dhe_rsa,:aes_256_cbc,:sha256},
                     {:dhe_dss,:aes_256_cbc,:sha256},
                     {:rsa,:aes_256_cbc,:sha256},
                     {:dhe_rsa,:aes_128_cbc,:sha256},
                     {:dhe_dss,:aes_128_cbc,:sha256},
                     {:rsa,:aes_128_cbc,:sha256},
                     {:dhe_rsa,:aes_256_cbc,:sha},
                     {:dhe_dss,:aes_256_cbc,:sha},
                     {:rsa,:aes_256_cbc,:sha},
                     {:dhe_rsa,:'3des_ede_cbc',:sha},
                     {:dhe_dss,:'3des_ede_cbc',:sha},
                     {:rsa,:'3des_ede_cbc',:sha},
                     {:dhe_rsa,:aes_128_cbc,:sha},
                     {:dhe_dss,:aes_128_cbc,:sha},
                     {:rsa,:aes_128_cbc,:sha},
                     {:rsa,:rc4_128,:sha},
                     {:rsa,:rc4_128,:md5},
                     {:dhe_rsa,:des_cbc,:sha},
                     {:rsa,:des_cbc,:sha} 
                    ]}],
          vpn_hub: "DEFAULT",
          vpn_port: "80",
          vpn_hostname: "vpn.evercam.io",
          vpn_keys_directory: ".evercam_keys",
          vpn_group_name: "clients",
          omapi_script: "../../bin/evercam-omapi.py",
          vpn_server_interface: "vpn_ether"

config :gateway, 
       exclude_interfaces: ['lo'],
       vpncmd_path: "vpncmd"

config :logger,
  backends: [{LoggerFileBackend, :info},
             {LoggerFileBackend, :error}]

config :logger, :info,
  path: "/var/apps/logs/vpn-service-info.log",
  level: :info

config :logger, :error,
  path: "/var/apps/logs/vpn-service-error.log",
  level: :error
