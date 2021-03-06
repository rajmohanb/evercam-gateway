defmodule Gateway.VPN.Client do
  @moduledoc "Handles VPN Client Functions: creating account, connecting accounting etc" 
  import Gateway.Utilities.External
  import Application
  require Logger

  @soft_ether_success 0
  @soft_ether_not_connected 37

  @doc "Restarts the VPN Client. FIXME: Hopefully this can be dispensed with once
  bug with setting MAC Address is removed. At present by design the system is not
  supposed to start and stop the actual VPN Client."
  def restart do
    command = shell("#{get_env(:gateway, :vpnclient_path)} stop")
    Logger.info(command.out)

    command = shell("#{get_env(:gateway, :vpnclient_path)} start")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Creates a VPN user account based on system configuration"
  def account_create do
    params = "#{get_env(:gateway, :vpn_account_name)}"  
             <> " /SERVER:#{get_env(:gateway, :vpn_hostname)}:#{get_env(:gateway, :vpn_port)}"
             <> " /HUB:#{get_env(:gateway, :vpn_hub)}"
             <> " /USERNAME:#{get_env(:gateway, :vpn_username)}"
             <> " /NICNAME:ether"

    command = shell("#{vpncmd} localhost /CLIENT /CMD AccountCreate #{params}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Sets the private key and public certificate required for user account to 
  access the VPN. These are loaded from system configuration."
  def account_cert_set do
    params = "#{get_env(:gateway, :vpn_account_name)}" 
             <> " /LOADCERT:#{x509_cert_file}" 
             <> " /LOADKEY:#{private_key_file}"
    command = shell("#{vpncmd} localhost /CLIENT /CMD AccountCertSet #{params}")
    Logger.info(command.out)
    {:ok, command.status}
  end

  @doc "Connects the user account"
  def account_connect do
    command = shell("#{vpncmd} localhost /CLIENT /CMD AccountConnect #{get_env(:gateway, :vpn_account_name)}")
    Logger.info(command.out)
    {:ok, command.status}
  end
 
  @doc "Checks on status of Account Connection"
  def account_status do
    command = shell("#{vpncmd} localhost /CLIENT /CMD AccountStatusGet #{get_env(:gateway, :vpn_account_name)}")
    case command.status do
      @soft_ether_success ->
        {:ok, :connected}
      @soft_ether_not_connected ->
        {:ok, :noconnection}
      _ ->
        Logger.info(command.status)
        {:ok, :unknown} 
    end
  end

  defp x509_cert_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :x509_cert_file))
  end

  defp private_key_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :private_key_file))
  end

  @doc "Gets the path of the user home directory. If it doesn't exist it creates it."
  def get_data_directory do
    home_path = Path.join(System.user_home, Application.get_env(:gateway, :data_folder)) 
    if !File.exists?(home_path), do: File.mkdir(home_path)
    home_path
  end

  defp vpncmd do
    get_env(:gateway, :vpncmd_path)
  end

end
