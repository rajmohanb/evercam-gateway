defmodule GatewayVPNService.Routing do
  @moduledoc "Obtains the complete list of rules for public forwarding on the VPN Server 
  and passes them to the Rules module which creates and maintains the forwarding rules
  using iptables"

  alias Gateway.Routing.Rules
  alias GatewayVPNService.Redis
  import Application

  use GenServer
  @name __MODULE__
  @rules_interval 15000

  # Client API
  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  @doc "Obtains forwarding rules from Gateway Database and adds them to the Server"
  def get_rules do
    case all_public_rules do
      {:ok, rules} ->
        rules
          |> process_rules
          |> Rules.replace
      _ ->
        #do nothing
      end
  end

  defp all_public_rules do
    Redis.query ["SMEMBERS", vpn_server_redis_key]
  end

  defp vpn_server_redis_key do
    "vpn_server:#{get_env(:gateway_vpn_service, :vpn_hostname)}:public_forwards"
  end

  # Transforms results from API into rules format for Gateway Routing Module
  defp process_rules(rules) do
    rules
      |> Enum.map(fn(x) -> 
              items = x |> String.split(":") |> List.to_tuple
              %{
                # Important! Note the switcheroo here. For the Server the "gateway_port" is actually
                # the port on the server which will be opened publicly. 
                :gateway_port => String.to_integer(elem(items,0)),
                # And it is this port which now represents the actual port on the gateway device that
                # is in the local LAN. TODO: fix naming conventions to prevent this confusion. For now
                # safer to maintain status quo.
                :port => String.to_integer(elem(items,1)),
                # And now this IP Address is the VPN ip address of the gateway device itself
                :ip_address => elem(items,2),
                :interface => Application.get_env(:gateway_vpn_service, :vpn_server_interface)
              }
            end)
  end

  # Server Callbacks
  def init([]) do
    :erlang.send(self, :get_rules)
    {:ok, nil}
  end

  # Gets rules and sets interval for next recursion
  def handle_info(:get_rules, _state) do
    get_rules
    :erlang.send_after(@rules_interval, self, :get_rules)
    {:noreply, nil}
  end

end
