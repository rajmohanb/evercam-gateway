defmodule Gateway.Discovery do
  alias Gateway.Discovery.Scan
  alias Gateway.Discovery.DiscoveryServer

  use GenServer
  @name __MODULE__
  @discovery_interval 600000

  # Client API
  @doc "Starts Discovery Process"
  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  @doc "Returns latest set of Discovery results"
  def results do
    DiscoveryServer.get   
  end

  # Server Callbacks
  def init([]) do
    case results do
      # if no results then run discovery immediately
      [] -> 
        :erlang.send(self, :discover)
      # otherwise wait the usual interval
      _ ->
        :erlang.send_after(@discovery_interval, self, :discover)
    end
    {:ok, nil}
  end

  @doc "Scans network, stores results in memory, uploads and sets intervals for rediscovery"
  def handle_info(:discover, _state) do
    Scan.scan_test 
      |> DiscoveryServer.put

    Application.get_env(:gateway, :gateway_id)
      |> Gateway.API.Devices.post!(results)

    :erlang.send_after(@discovery_interval, self, :discover)
    {:noreply, nil}
  end

end

