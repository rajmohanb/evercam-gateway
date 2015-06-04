defmodule Gateway.Discovery.Scan do
  alias Gateway.Discovery.Network
  alias Gateway.Discovery.Host
  alias Gateway.Utilities.Parallel

  # Timeout for each host scan in milliseconds
  @timeout 600000

  @doc "Returns a complete list of all network devices and associated data"
  def scan_basic do   
    Network.scan_all()
      |> scan_hosts
  end

  @doc "Experimental use only. Scan beyond interface subnets. This will potentially 
  identify hosts that cannot be routed to. It could take a very long time - think days." 
  def scan_deep do
    ["192.0.0.0/24", "192.168.0.0/16", "169.254.0.0/16", "172.16.0.0/12"]
      |> Enum.reduce([],fn(x,acc) -> [Network.scan_all(x) | acc] end)
      |> List.flatten
      |> scan_hosts
  end

  @doc "Scans default IP addresses used by camera manufacturers. i.e. Hikvision: 192.0.0.64. 
  This may identify hosts that cannot be routed to."
  def scan_default do
    ["192.0.0.64", "192.168.0.90"]
      |> Enum.reduce([],fn(x,acc) -> [Network.scan_all(x) | acc] end)
      |> List.flatten
      |> scan_hosts
  end

  def scan_test do
  ["172.16.0.21"]
      |> Enum.reduce([],fn(x,acc) -> [Network.scan_all(x) | acc] end)
      |> List.flatten
      |> scan_hosts

  end

  defp scan_hosts(hosts) do
    # Use a parallel map to run scans on every host concurrently. Add a timeout 
    # for individual scans.
    hosts
      |> Parallel.map(@timeout, fn(host) -> Map.put_new(host, "ports", Host.scan(host["ip_address"])) end)
      # Remove the ones that failed completely to return data
      |> Enum.filter(fn(x) -> 
            case x do
              {:error, :processfailed} ->
                false
              _->
                true
            end
         end)
      # Remove the ones where the ports failed to scan
      |> Enum.filter(fn(x) ->
           x["ports"] != {:error, :parsingfailed}
         end)
  end

end
