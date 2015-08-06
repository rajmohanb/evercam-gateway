defmodule Gateway.Discovery.Scan do
  import Gateway.Utilities.External
  import Application
  require Logger

  @exclude_evercam_values ["lan_ip", "lan_http_port", "lan_rtsp_port"]

  @doc "Returns a complete list of all network devices and associated data"
  def run do   
    evercam_discovery
      |> parse_evercam_discovery
  end

  # Runs the evercam discovery command (set in config) and returns results
  defp evercam_discovery do
    command = shell("#{get_env(:gateway, :evercam_discovery_cmd)}")
    Logger.error(command.err)
    Logger.info(command.out)
    {:ok, command.out}
  end

  # Parses the results of Evercam Discovery into format required by Gateway API
  defp parse_evercam_discovery({:ok, results}) do
    results 
      |> Poison.decode!
      |> Map.fetch!("cameras")
      |> cameras_to_devices
  end

  # Takes the lists of cameras and turns them into the (slightly) more generic "devices" 
  # format that the Gateway API expects
  defp cameras_to_devices(cameras) do
    cameras 
      |> Enum.map(fn(x) -> camera_to_device(x) end)
  end

  # Takes a single camera Map and turns it into a Device Map
  # TODO: this is pretty horrible
  defp camera_to_device(camera) do
    # Add the top level values that are being renamed 
    camera = camera |> Map.put_new("ip_address", camera["lan_ip"])

    # Turn the basic http and rtsp port values and turn them into an array of maps
    ports = []
    if camera["lan_http_port"] != nil do
      ports = ports ++ [%{"port_id" => camera["lan_http_port"], "service" => "http"}]
    end
    if camera["lan_rtsp_port"] != nil do
      ports = ports ++ [%{"port_id" => camera["lan_rtsp_port"], "service" => "rtsp"}]
    end
 
    camera = camera |> Map.put_new("ports", ports)

    # Takes the camera result and strips out values that are being recast
    camera = camera |> Map.drop(@exclude_evercam_values)

    camera
  end 
  
end
