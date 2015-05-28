defmodule Gateway.Init.Configuration do
  @moduledoc "Handles loading and setting of core Gateway configuration"
  alias Gateway.Init.Network

  @doc "Loads complete core configuration from gateway directory in user home directory"
  def load do
    case File.read(config_file) do
      {:ok, main_config} ->
        {:ok, token} = File.read(token_file)
        {:ok, mac_address} = File.read(Network.mac_file)

        config = main_config |> Poison.decode!
                   |> Map.put("gateway_api_token", token |> Poison.decode!)
                   |> Map.put("mac_address", mac_address)

        {:ok, config}
      {:error, _} ->
        {:error, :noconfig}
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
    Poison.encode!(config)
      |> write
  end

  @doc "Write config to system file in user home directory"
  def write(config) when is_binary(config) do
    {:ok, file} = File.open(config_file, [:write])
    IO.binwrite(file, config)
    File.close file
  end

  @doc "Write API token to system file in user home directory"
  def write_token(token) when is_map(token) do
    Poison.encode!(token)
      |> write_token
  end

  @doc "Writes API Token to a system file in user home directory"
  def write_token(token) when is_binary(token) do
    {:ok, file} = File.open(token_file, [:write])
    IO.binwrite(file, token)
    File.close file
  end

  @doc "Gets the path of the user home directory. If it doesn't exist it creates it."
  def get_data_directory do
    home_path = Path.join(System.user_home, Application.get_env(:gateway, :data_folder)) 
    if !File.exists?(home_path), do: File.mkdir(home_path)
    home_path
  end

  defp config_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :config_file))
  end

  defp token_file do
    Path.join(get_data_directory, Application.get_env(:gateway, :token_file))
  end

end
