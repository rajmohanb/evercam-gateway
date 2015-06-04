defmodule Gateway.VPN.Interface do
  @moduledoc "Handles everything to do with the Virtual NIC required by the VPN"
  import Gateway.Utilities.External
  import Application
  require Logger

  @doc "Creates a Virtual NIC for use with VPN. This command is idempotent: if 
  a virtual NIC of this name exists then no new one will be created. We will always
  be creating a NIC for the local host and always only one with always the same name"
  def create do
    command = shell("#{vpncmd} localhost /CLIENT /CMD NicCreate ether")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Set the specified MAC Address on the Virtual NIC. This MAC address is
  supplied by the server which will have configured a static lease for it."
  def configure_mac do
    command = shell("#{vpncmd} localhost /CLIENT /CMD NicSetSetting ether /MAC:#{get_env(:gateway, :vpn_mac_address)}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Sets networking parameters for Virtual NIC. This must be called after VPN
  Account is connected in order to work. It obtains a static lease from DHCP server
  on VPN Network."
  def configure_network do
    command = shell("sudo dhclient -v vpn_ether")
    Logger.info(command.out)
    {:ok, command.status}
  end

  defp vpncmd do
    get_env(:gateway, :vpncmd_path)
  end

end
