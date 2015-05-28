defmodule Gateway.Init.Network do
  alias Gateway.Utilities.Network, as: NetUtils
  alias Gateway.Init.Configuration

  @doc "Attempts to load Primary MAC Address from user home directory. If not
  available it determines it dynamically and saves to home directory."
  def get_primary_mac_address do
    primary_mac_from_file    
  end

  # Get mac address from gateway data folder
  defp primary_mac_from_file do
    case File.read(mac_file) do
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
    {:ok, file} = File.open(mac_file, [:write])
    IO.binwrite(file, mac_address)
    File.close(file)
  end

  def mac_file do
    Path.join(Configuration.get_data_directory, Application.get_env(:gateway, :mac_file)) 
  end

end
