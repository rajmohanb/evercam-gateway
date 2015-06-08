defmodule GatewayVPNService.DHCP do
  import Gateway.Utilities.External

  @doc "Calls a python script that can a static lease host entry in the
  DHCPD configuration of the server"
  def add_static_lease(ip_address, mac_address, host_name) do
    command = shell("#{omapi_script} #{ip_address} #{mac_address} #{host_name}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Checks the TODO: See if we can get OMAPI Lookup working for these
  static leases. Currently it isn't. Not sure whether that's a feature or 
  a big. The best we can do is pick an IP and then check that it isn't 
  assigned to a dynamic host using our OMAPI Lookup script."
  def get_free_ip_address(host_name) do
    {:error, :not_implemented}
  end

  defp omapi_script do
    Application.get_env(:gateway_vpn_service, :omapi_script)
  end

end
