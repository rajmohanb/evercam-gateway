defmodule GatewayVPNService.DHCP do
  import Gateway.Utilities.External
  import Application
  alias Gateway.Utilities.Network, as: NetUtils
  alias GatewayVPNService.Redis 
  require Logger

  # This is the range of allowed IP Addresses for Gateways on the VPN
  @ip_range_start 170709039 #{10,44,208,47}
  @ip_range_end 170713039 #{10,44,223,207}

  @doc "Calls a python script that can a static lease host entry in the
  DHCPD configuration of the server"
  def add_static_lease(ip_address, mac_address, host_name) do
    command = shell("#{omapi_script} add #{ip_address} #{mac_address} #{host_name}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Returns a free IP address in the allowed range. TODO: See if we can get 
  OMAPI Lookup working for these static leases. Currently it isn't. Not sure 
  whether that's a feature or a bug. The best we can do is pick an IP and 
  then check that it isn't assigned to a dynamic host using our OMAPI Lookup script."
  def get_free_ip_address do  
    next_ip = get_all_gateway_ips
      |> Enum.map(fn(x) -> NetUtils.to_ipinteger(x) end)
      |> Enum.sort
      |> List.last
      |> +1
      |> get_free_ip_address
  end

  def get_free_ip_address(current_ip) when is_integer(current_ip) and current_ip < @ip_range_end do
    if omapi?(current_ip) do
      get_free_ip_address(current_ip+1)
    else
      reserve_ip_address(current_ip)
    end
  end

  # Tries to reserve the ip address in question. If it succeeds then it 
  # returns it, if not it starts incrementing again 
  defp reserve_ip_address(ip) when is_integer(ip) do
    ip_address = ip |> NetUtils.to_ipaddress |> NetUtils.to_ipstring
    if !reserve_ip_address(ip_address) do
      get_free_ip_address(ip+1)
    else
      ip_address
    end
  end
 
  # Tries to add as key to REDIS set
  defp reserve_ip_address(ip) when is_binary(ip) do
    {:ok, result} = Redis.query ["SADD",vpn_server_redis_key, ip]
    if result == "1" do
      true
    else
      false
    end
  end

  # Retrieves list of all gateway ips from REDIS K-V store 
  defp get_all_gateway_ips do
    {:ok, ips} = Redis.query ["SMEMBERS",vpn_server_redis_key]
    if Enum.empty?(ips), do: ips = [@ip_range_start |> NetUtils.to_ipaddress |> NetUtils.to_ipstring]
    ips |> Enum.map(fn(x) -> NetUtils.to_ipaddress(x) end)
  end

  # Runs an OMAPI script which queries DHCP server to see if an IP has been assigned
  # This is to ensure we don't collide with properly dynamic leases issued to VPN
  # clients
  defp omapi?(ip_address) do
    command = shell("#{omapi_script} lookup #{ip_address}")
    Logger.info(command.out)
    case command.status do
      0 ->
        false # Found no entry
      1 ->
        true # Found an existing entry
      _ ->
        Logger.error("Error looking up OMAPI: #{command.out} #{command.status}")
        true # Let's assume there is an entry rather than risk collision
    end
 end

  defp omapi_script do
    get_env(:gateway_vpn_service, :omapi_script)
  end

  defp vpn_server_redis_key do
    "vpnserver:#{get_env(:gateway_vpn_service, :vpn_hostname)}:gateway_ips"
  end

end
