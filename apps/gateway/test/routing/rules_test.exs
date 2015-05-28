defmodule Gateway.Routing.RulesTest do
  use ExUnit.Case, async: false
  alias Gateway.Routing.Rules
  @moduledoc "Tests the addition and removal of rules. Has to be synchronous as it relies on OS state."

  setup_all do
    # Start RulesServer and Stash manually
    {:ok, stash_pid} = Gateway.Utilities.Stash.start_link 
    Gateway.Routing.Rules.start_link(stash_pid) 
   
    :ok
  end

  # Make tests independent
  setup do
    Rules.clear

    on_exit fn ->
      Rules.clear
    end
  end

  test "Adding valid rule succeeds" do
    assert :ok == Rules.add(%{:gateway_port=>8080,:ip_address=>test_ip,:port=>80})
  end

  test "Adding a duplicate rule fails" do
    Rules.add(%{:gateway_port=>8080,:ip_address=>test_ip,:port=>80})
    assert {:error, :eexists} == Rules.add(%{:gateway_port=>8080,:ip_address=>test_ip,:port=>80})
  end

  test "Adding an invalid rule fails" do
    assert {:error, :eiptables} == Rules.add(%{:gateway_port=>8080, :ip_address=>test_ip, :port=>8000000})
  end

  test "Removing an existing rule succeeds" do
    Rules.add(%{:gateway_port=>8080,:ip_address=>test_ip,:port=>80})
    assert :ok == Rules.remove(%{:gateway_port=>8080,:ip_address=>test_ip,:port=>80})
  end

  test "Removing a non-existent rule fails" do 
    assert {:error, :eiptables} == Rules.remove(%{:gateway_port=>8080,:ip_address=>test_ip,:port=>80})
  end

  test "Adding a bunch of rules at once produces a list of failures and successes" do
    assert [:ok, {:error, :eexists}, :ok] == Rules.add(rules_list)
  end

  test "Replacing a group of rules, removes those omitted and adds new ones" do
    Rules.add(rules_list)
    Rules.replace(replacement_rules_list)
    assert Enum.sort(replacement_rules_list) == Enum.sort(Gateway.Routing.RulesServer.get)
  end

  # A list of sample rules
  defp rules_list do
   [ 
      %{:gateway_port=>8080,:ip_address=>test_ip,:port=>80},
      %{:gateway_port=>8080,:ip_address=>test_ip,:port=>80},
      %{:gateway_port=>9080,:ip_address=>test_ip,:port=>8000}
    ]
  end

  # A list of replacement rules
  defp replacement_rules_list do
    [ 
      %{:gateway_port=>9080,:ip_address=>test_ip,:port=>8000},
      %{:gateway_port=>10080,:ip_address=>test_ip,:port=>4040}
    ]
  end

  # Generates an IP that will work with at least one active Network interface on local machine
  # TODO: Discuss whether this is the right way to do this. Perhaps automation is not the answer.
  defp test_ip do
    alias Gateway.Utilities.Network, as: NetUtils
    
    NetUtils.get_interfaces
      # Filter out interfaces that have no ip address
      |> Enum.filter(fn(x) -> 
           NetUtils.get_interface_attribute(x, :addr) != nil
         end)
      # grab the first one
      |> Enum.at(0)
      # Get the ip address as a 4-tuple
      |> NetUtils.get_interface_attribute(:addr)
      # Increment the last value in the tuple
      |> (fn({oct1,oct2,oct3,oct4}) -> {oct1,oct2,oct3,oct4+1} end).()
      # Turn the result into a string
      |> NetUtils.to_ipstring
  end

end
