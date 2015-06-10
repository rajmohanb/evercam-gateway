defmodule GatewayVPNService.Server.Response do
  import Application
  alias GatewayVPNService.Crypto
  alias GatewayVPNService.VPN.Server, as: VPNServer
  alias GatewayVPNService.DHCP

  @doc "Takes in an authenticated request and generates required response"
  def create(request) when is_map(request) do
    gateway_id = request["gateway_id"]
    vpn_username =  "gateway#{gateway_id}" 
    vpn_local_hostname = "gateway#{gateway_id}.#{get_env(:gateway_vpn_service, :vpn_hostname)}"
    vpn_ip_address = DHCP.get_free_ip_address
    {:ok, key, certificate} = Crypto.generate_key_pair(gateway_id)
    {:ok, mac_address} = Crypto.generate_mac_address
    {:ok, certificate_path} = Crypto.store_certificate(certificate, gateway_id)
    {:ok, 0} = VPNServer.user_create(vpn_username)
    {:ok, 0} = VPNServer.user_cert_set(vpn_username, certificate_path)
    {:ok, 0} = DHCP.add_static_lease(vpn_ip_address, mac_address, vpn_local_hostname)
    #TODO: Dynamically Add a DNS Entry to the VPN DNS Server.

    %{:vpn_username => vpn_username,
      :vpn_hub => get_env(:gateway_vpn_service, :vpn_hub), 
      :vpn_port => get_env(:gateway_vpn_service, :vpn_port), 
      :vpn_hostname => get_env(:gateway_vpn_service, :vpn_hostname),
      :vpn_local_hostname =>  vpn_local_hostname,
      :vpn_mac_address => mac_address,
      :vpn_ip_address => vpn_ip_address,
      :vpn_private_key => key,
     :vpn_certificate => certificate
    }
  end

  def send(response, socket) do
    :ssl.send(socket, response) 
  end

  def send_failure(reason, socket) do
    %{:error => reason} 
      |> Poison.encode!
      |> :ssl.send(socket) 
  end

end
