defmodule GatewayVPNService.VPN.Server do
  import Gateway.Utilities.External
  import Application
  require Logger

  @server "localhost"
  @hub "DEFAULT"

  def user_create(username) do
    group_name = get_env(:gateway_vpn_service, :vpn_group_name)
    params = "#{username} /GROUP:#{group_name} /REALNAME:#{username} /NOTE:Evercam Gateway User" 
    command = shell("#{vpncmd} #{@server} /SERVER /HUB:#{@hub} /CMD UserCreate #{params}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  def user_cert_set(username, certificate_path) do
    params = "#{username} /LOADCERT:#{certificate_path}" 
    command = shell("#{vpncmd} #{@server} /SERVER /HUB:#{@hub} /CMD UserCertSet #{params}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  def vpncmd do
    get_env(:gateway, :vpncmd_path)
  end

end
