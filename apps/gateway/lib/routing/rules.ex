defmodule Gateway.Routing.Rules do
  @moduledoc "Controls use of iptables(8) for dynamically adding and removing
  routing rules. These rules direct traffic from the Gateway to other LAN devices."
  alias Gateway.Routing.RulesServer
  import Gateway.Utilities.External

  @doc "Clears all existing user-generated iptables rules in the OS. Starts the genserver that
  stores the rules state"
  def start_link(stash_pid) do
    flush_iptables
    RulesServer.start_link(stash_pid)
  end

  @doc """
    Adds multiple forwarding rules. Removes any existing rules not contained in the list.
  """
  def replace(rules) when is_list(rules) do
    current_rules = all_rules

    # Remove old rules not in newly passed list
    current_rules
      |> Enum.filter(fn(x) -> !Enum.member?(rules,x) end)
      |> Enum.each(fn(x) -> remove(x) end)

    # Add the list of new rules
    rules
      |> Enum.map(fn(x) -> add(x) end)
  end

  @doc "Adds multiple forwarding rules. Leaves existing rules unchanged."
  def add(rules) when is_list(rules) do
    rules
      |> Enum.map(fn(x) -> add(x) end)
  end

  @doc """
  Adds a forwarding rule. If rule already exists, it is ignored. If a different rule
  with the same :gateway_port exists then it will be removed automatically and replaced.
  
  Example: Rules.add(%{:gateway_port=>8080, :ip_address=>"172.16.0.21", :port=>80})

  This would forward the network device on 172.16.0.21:80 on port 8080 of the Gateway
  """  
  def add(rule) when is_map(rule) do
    if !exists?(rule) do
      # Remove any rule with the same Gateway port
      rules(rule[:gateway_port])
        |> Enum.each(fn(x) -> remove(x) end)
      
      pre = pre_routing(rule[:gateway_port], rule[:ip_address], rule[:port])
      post = post_routing(rule[:ip_address], rule[:port], rule[:interface])
      status = add(pre,post)
     
      # Only actually add it to the rules list if the addition in iptables was successful
      if status == 0 do
        RulesServer.add(rule)
      else
        {:error, :eiptables}
      end
    else
      {:error, :eexists}
    end
  end

  @doc """
  Removes a forwarding rule.

  Example: Rules.remove(%{:gateway_port=>8080, :ip_address=>"172.16.0.21", :port=>80})

  This would stop forwarding the network device on 172.16.0.21:80 on port 8080 of the Gateway 
  """
  def remove(rule) when is_map(rule) do
    pre = pre_routing(rule[:gateway_port], rule[:ip_address], rule[:port])
    post = post_routing(rule[:ip_address], rule[:port], rule[:interface])
    status = remove(pre,post)
  
    if status == 0 do
      RulesServer.remove(rule)
    else
      {:error, :eiptables}
    end
  end

  @doc """
    Clears all rules
  """
  def clear do
    flush_iptables
    RulesServer.clear
  end

  # Returns a list of rules with a specific :gateway_port - should always be list of 1, but you
  # never know
  defp rules(gateway_port) when is_integer(gateway_port) do
    RulesServer.get({:gateway_port, gateway_port})
  end

  # Returns the entire list of rules
  defp all_rules do
    RulesServer.get()
  end

  # Checks if an identical rule already exists
  defp exists?(rule) when is_map(rule) do
    all_rules
      |> Enum.any?(fn(x) -> x == rule end)
  end
  
  # Initialise IP Tables
  defp flush_iptables do 
    # Flush all existing NAT rules
    shell("sudo iptables -t nat -F")
    shell("sudo iptables -X")
  end

  # Uses iptables to add a complete rule. A rule must have both a pre-route and a post-route 
  defp add(pre, post) do
    command = shell("sudo iptables -t nat -A #{pre}") 
    # prevent the post-route being added if pre-route failed. Otherwise buggy networking may ensue.
    if command.status == 0 do
      command = shell("sudo iptables -t nat -A #{post}") 
    end
    command.status
  end

  # Uses iptables to remove an existing rule. It removes both the pre and post routes. 
  defp remove(pre,post) do
    command = shell("sudo iptables -t nat -D #{pre}") 
    # prevent the post-route being deleted if pre-route deletion failed. Otherwise buggy networking may ensue.
    if command.status == 0 do
      # TODO: Figure out what to do if the interface IP changed between adding rule and removing it
      # This is really an edge case because rules are regenerated on reboot anyway. Still has to be
      # considered
      command = shell("sudo iptables -t nat -D #{post}") 
    end
    command.status
  end

  # Generates a pre-routing rule string
  defp pre_routing(gateway_port, host_ip_address, host_port) do
    "PREROUTING -p tcp --dport #{gateway_port} -j DNAT --to-destination #{host_ip_address}:#{host_port}"
  end

  # Generates a post-routing rule string.
  defp post_routing(host_ip_address, host_port, out_interface \\ nil) do
    case out_interface do
      nil ->
        "POSTROUTING -p tcp -d #{host_ip_address} --dport #{host_port} -j SNAT --to-source #{interface_ip_address(host_ip_address)}"
      _ ->
        "POSTROUTING -p tcp -o #{out_interface} -d #{host_ip_address} --dport #{host_port} -j SNAT --to-source #{interface_ip_address(host_ip_address)}"
    end
  end

  # Determines relevant network interface IPv4 address based on an IP address of a network device
  defp interface_ip_address(ip_address) do
    alias Gateway.Utilities.Network, as: NetUtils
    
    ip_address
      |> NetUtils.to_ipaddress
      |> NetUtils.get_device_interface 
      |> NetUtils.get_interface_attribute(:addr)
      |> NetUtils.to_ipstring
  end

end
