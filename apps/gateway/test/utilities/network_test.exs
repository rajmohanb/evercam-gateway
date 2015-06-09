defmodule Gateway.Utilities.NetworkTest do
  use ExUnit.Case, async: true
  alias Gateway.Utilities.Network

  doctest Network
  
  # This is the range of allowed IP Addresses for Gateways on the VPN
  # but can be any range for test purposes
  @netmask {255,255,240,0}
  @test_ip {10,44,208,1}
  @ip_range_start {10,44,208,47}
  @ip_range_end {10,44,223,207}

  test "that interfaces are parsed into Map with string representations of IP and MAC Addresses" do
    assert sample_interfaces |> Network.parse_interfaces ==
        [%{:flags => [:up, :broadcast, :running, :multicast],
          "mac_address" => "00:25:90:a6:f7:8c", "name" => "eth0"},
        %{:flags => [:broadcast, :multicast], "mac_address" => "00:25:90:a6:f7:8d",
          "name" => "eth1"},
        %{:flags => [:up, :broadcast, :running, :multicast],
          "broadcast_address" => "172.16.0.255", "ip_address" => "172.16.0.184",
          "ipv6_address" => "FE80::12FE:EDFF:FE1F:560D",
          "ipv6_net_mask" => "FFFF:FFFF:FFFF:FFFF::",
          "mac_address" => "10:fe:ed:1f:56:0d", "name" => "wlan1",
          "net_mask" => "255.255.255.0"}]   
  end

  test "that interface attributes are retrieved correctly" do
    [_,_,interface] = sample_interfaces
    assert Network.get_interface_attribute(interface, :addr) == {172,16,0,184}
  end

  test "that random ip generator generates IPs in correct subnet" do
    assert [1..500]
              |> Enum.all?(fn(x) -> 
              random_ip = Network.generate_random_ip(@ip_range_start, @ip_range_end)
              Network.same_subnet?(random_ip, @test_ip, @netmask)
            end)
  end

  defp sample_interfaces do
    [{'eth0',
      [flags: [:up, :broadcast, :running, :multicast],
      hwaddr: [0, 37, 144, 166, 247, 140]]},
    {'eth1',
      [flags: [:broadcast, :multicast], hwaddr: [0, 37, 144, 166, 247, 141]]},
    {'wlan1',
      [flags: [:up, :broadcast, :running, :multicast],
      hwaddr: [16, 254, 237, 31, 86, 13], addr: {172, 16, 0, 184},
      netmask: {255, 255, 255, 0}, broadaddr: {172, 16, 0, 255},
      addr: {65152, 0, 0, 0, 4862, 60927, 65055, 22029},
      netmask: {65535, 65535, 65535, 65535, 0, 0, 0, 0}]}]
  end

end
