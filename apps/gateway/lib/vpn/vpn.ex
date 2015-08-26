defmodule Gateway.VPN do
  @moduledoc "Brings together client and interface functions for VPN"
  alias Gateway.VPN.Client
  alias Gateway.VPN.Interface
  require Logger

  @doc "Joins client to VPN. This relies on the vpnclient service being active but that
  is the system's responsibility (for now). Since all the operations here are idempotent
  it doesn't seem harmful to repeat them all every time we need to join VPN. For future
  reference I've indicated the ones that actually only need to be run on the very first
  configuration"
  def join do
    # Creates a Virtual NIC. Only actually required once.
    Interface.create

    # Creates the local VPN Account used to connect to VPN
    # Only actually required once
    Client.account_create

    # Loads in the private/public key required to connect to VPN
    # Only actually required once
    Client.account_cert_set

    # Initiates the client connection to the VPN
    # Required on every startup
    Client.account_connect
 
     # Sets the MAC address to that expected by DHCP Server
    # on VPN Network. Only actually required once. Moved it to last
    # position as it appears that on first creation the NIC is not
    # functioning before this is called and as a result this has no
    # effect
    Interface.configure_mac

   # Ensures the virtual NIC goes through DHCP process on VPN
    # Required on every startup. Spawn a separate process so the system can
    # continue while dhcp client waits until Virtual adaptor is actually connected
    spawn fn ->
      send self(), Client.account_status
      receive do
        {:ok, :connected} ->
          Interface.configure_network
        {:ok, status} ->
          Logger.info("VPN Account Status: #{status}")
          send self(), Client.account_status
      end 
    end
  end

end
