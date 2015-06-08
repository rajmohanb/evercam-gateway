defmodule GatewayVPNService.Server.Response do
  import Application
  alias GatewayVPNService.Crypto
  alias GatewayVPNService.VPN.Server, as: VPNServer

  @doc "Takes in an authenticated request and generates required response"
  def create(request) when is_map(request) do
    gateway_id = request["gateway_id"]
    vpn_username =  "gateway#{gateway_id}" 
    vpn_local_hostname = "gateway#{gateway_id}.#{get_env(:gateway_vpn_service, :vpn_hostname)}"
    {:ok, key, certificate} = Crypto.generate_key_pair(gateway_id)
    {:ok, mac_address} = Crypto.generate_mac_address
    {:ok, certificate_path} = Crypto.store_certificate(certificate, gateway_id)
    {:ok, 0} = VPNServer.user_create(vpn_username)
    {:ok, 0} = VPNServer.user_cert_set(certificate_path)
    {:ok, 0} = DHCP.add_static_lease(DHCP.get_free_ip_address(vpn_local_hostname), mac_address, vpn_local_hostname)

    %{:vpn_username => vpn_username,
      :vpn_hub => get_env(:gateway_vpn_service, :vpn_hub), 
      :vpn_port => get_env(:gateway_vpn_service, :vpn_port), 
      :vpn_hostname => get_env(:gateway_vpn_service, :vpn_hostname),
      :vpn_local_hostname =>  vpn_local_hostname,
      :vpn_mac_address => mac_address,
      :vpn_private_key => key,
     :vpn_certificate => certificate
    }
  end

  def send(response, socket) do
    IO.inspect response     
  end

  def send_failure(:authentication_failed, socket) do

  end

end
