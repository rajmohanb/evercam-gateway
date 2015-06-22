defmodule Gateway.VPN do
  @moduledoc "Brings together client and interface functions for VPN"
  alias Gateway.VPN.Client
  alias Gateway.VPN.Interface

  @doc "Joins client to VPN. This relies on the vpnclient service being active but that
  is the system's responsibility (for now). Since all the operations here are idempotent
  it doesn't seem harmful to repeat them all every time we need to join VPN. For future
  reference I've indicated the ones that actually only need to be run on the very first
  configuration"
  def join do
    # Creates a Virtual NIC. Only actually required once.
    Interface.create

    # Sets the MAC address to that expected by DHCP Server
    # on VPN Network. Only actually required once 
    Interface.configure_mac

    # Creates the local VPN Account used to connect to VPN
    # Only actually required once
    Client.account_create

    # Loads in the private/public key required to connect to VPN
    # Only actually required once
    Client.account_cert_set

    # Initiates the client connection to the VPN
    # Required on every startup
    Client.account_connect
 
    # Ensures the virtual NIC goes through DHCP process on VPN
    # Required on every startup
    Interface.configure_network
  end

end
