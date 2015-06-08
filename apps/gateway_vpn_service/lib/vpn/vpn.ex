defmodule GatewayVPNService.VPN.Server do
  alias Gateway.Utilities.External
  import Application
  require Logger

  @server "localhost"
  @hub "DEFAULT"

  def user_create(username) do
    group_name = get_env(:gateway_vpn_service, :vpn_group_name)
    params = "#{username} /GROUP:#{group_name} /NOTE:Evercam Gateway User" 
    command = shell("#{vpn_cmd} #{@server} /SERVER /HUB:#{@hub} /CMD UserCreate #{params}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  def user_cert_set(certificate_path) do
    params = "#{username} /LOADCERT:#{certificate_path}" 
    command = shell("#{vpn_cmd} #{@server} /SERVER /HUB:#{@hub} /CMD UserCertSet #{params}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  def vpncmd do
    get_env(:gateway_vpn_service, :vpncmd_path)
  end

end
