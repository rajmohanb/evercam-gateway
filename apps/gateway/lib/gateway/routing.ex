defmodule Gateway.Routing do
  @moduledoc "Obtains forwarding rules for the gateway from API and adds them"
  alias Gateway.Routing.Rules

  use GenServer
  @name __MODULE__
  @rules_interval 15000

  # Client API
  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  @doc "Obtains forwarding rules from API and adds them to local Gateway"
  def get_rules do
    Application.get_env(:gateway, :gateway_id)
      |> Gateway.API.Rules.get!
      |> process_rules
      |> Rules.replace
  end

  # Transforms results from API into rules format for Gateway
  defp process_rules(rules) do
    rules
      |> Enum.map(fn(rule) -> 
           %{:gateway_port => rule["local_port_id"], 
             :port => rule["port_id"],
             :ip_address => rule["ip_address"]}
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
