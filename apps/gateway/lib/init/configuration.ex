defmodule Gateway.Init.Configuration do
  @moduledoc "Handles loading and setting of core Gateway configuration"
  alias Gateway.Utilities.Network, as: NetUtils
  require Logger 
 
  @doc "Loads complete core configuration from gateway directory in user home directory"
  def load do
    case read_file(config_file) do
      {:ok, main_config} ->
        {:ok, token} = File.read(token_file)
        {:ok, mac_address} = File.read(mac_file)

        config = main_config |> Poison.decode!
                   |> Map.put("gateway_api_token", token |> Poison.decode!)
                   |> Map.put("mac_address", mac_address)

        {:ok, config}
      {:error, _} ->
        {:error, :noconfig}
    end
  end

  @doc "Loads only the API token"
  def load_token do
    case read_file(token_file) do
      {:ok, token} ->
        {:ok, token |> Poison.decode!}
      _ ->
        {:error, :notoken}
    end
  end

  @doc "Load m2m Secret"
  def load_m2m_secret do
    case read_file(m2m_secret_file) do 
      {:ok, body} ->
        body
      _ ->
        nil
    end
  end

  @doc "Loads a given config into Application Environment."
  def set_environment(config) do
    config
      |> Map.to_list
      |> Enum.each(fn(kv) -> 
                     {k,v} = kv
                     Application.put_env(:gateway, String.to_atom(k), v)
                  end)
  end

  @doc "Write config to system file in user home directory"
  def write(config) when is_map(config) do
    # Separate out the VPN Cert and Key and write them separately
    write_public_key(config["vpn_public_key"])
    write_private_key(config["vpn_private_key"])

    config
      |> Map.delete("vpn_private_key")
      |> Map.delete("vpn_public_key")
      |> Poison.encode!
      |> write
  end

  @doc "Write config to system file in user home directory"
  def write(config) when is_binary(config) do
    write_file(config_file, config)
  end

  @doc "Write API token to system file in user home directory"
  def write_token(token) when is_map(token) do
    Poison.encode!(token)
      |> write_token
  end

  @doc "Writes API Token to a system file in user home directory"
  def write_token(token) when is_binary(token) do
    write_file(token_file, token)
  end

  @doc "Writes m2m_secret file"
  def write_m2m_secret(m2m_secret) do
    write_file(m2m_secret_file, m2m_secret)
  end

  @doc "Writes VPN Private Key"
  def write_private_key(key) do
    write_file(private_key_file, key)
  end

  @doc "Writes VPN Public Key"
  def write_public_key(key) do
    write_file(x509_cert_file, key)
  end

  @doc "Gets the path of the user home directory. If it doesn't exist it creates it."
  def get_data_directory do
    home_path = Path.join(System.user_home, Application.get_env(:gateway, :data_folder)) 
    if !File.exists?(home_path), do: File.mkdir(home_path)
    home_path
  end

  @doc "Attempts to load Primary MAC Address from user home directory. If not
  available it determines it dynamically and saves to home directory."
  def get_primary_mac_address do
    primary_mac_from_file    
  end

  # Get mac address from gateway data folder
  defp primary_mac_from_file do
    case read_file(mac_file) do
      {:ok, body} ->
        body
      {:error, :enoent} ->
        write_mac_file
        primary_mac_from_file
      {:error, _reason} ->
        # Log an error
    end
  end 

  # Get Primary Interface MAC Address and write it to a file
  defp write_mac_file do
    mac_address = NetUtils.get_primary_mac_address
    write_file(mac_file, mac_address)
  end

  defp write_file(filename, contents) do
    {:ok, file} = File.open(filename, [:write])
    IO.binwrite(file, contents)
    File.close file
  end

  defp read_file(filename) do
    case File.read(filename) do
      {:ok, body} ->
        {:ok, body |> String.rstrip(?\n) }
      {:error, reason} ->
        {:error, reason}
      _ ->
        nil
    end
  end

  defp mac_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :mac_file)) 
  end

  defp config_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :config_file))
  end

  defp token_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :token_file))
  end

  defp m2m_secret_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :m2m_secret_file))
  end

  defp x509_cert_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :x509_cert_file))
  end

  defp private_key_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :private_key_file))
  end

end
