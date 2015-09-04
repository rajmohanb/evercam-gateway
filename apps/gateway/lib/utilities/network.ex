defmodule Gateway.Utilities.Network do
  use Bitwise

  @doc """
  Turns an erlang-style IPv4 or IPv6 address into a string
  
  ### Examples

      iex> Network.to_ipstring({192,168,0,45})
      "192.168.0.45"
  """
  def to_ipstring(address) when is_tuple(address) do
    address
      |> :inet.ntoa
      |> to_string  
  end

  @doc """
  Turns a quad-dotted IPv4 string into an erlang-style IP Address
  
  ### Examples
 
      iex> Network.to_ipaddress("192.168.0.45")
      {192,168,0,45}
  """
  def to_ipaddress(address) when is_binary(address) do
    {:ok, ip_address} = address
      |> String.to_char_list
      |> :inet.parse_ipv4_address
      ip_address
  end

  @doc """
  Turns a 32 bit decimal integer into an IPv4 address
  
  ### Examples

      iex> Network.to_ipaddress(3232235565)
      {192,168,0,45}
  """
  def to_ipaddress(address) when is_integer(address) do
    [24,16,8,0]
      |> Enum.map(fn(x) -> (address >>> x) &&& 0xFF end) 
      |> List.to_tuple
  end

  @doc """
  Turns a IPv4 Bitmask (decimal netmask like /24) into a 4-tuple 
  
  ### Examples
    
      iex> Network.to_netmask(24)
      {255,255,255,0}
  """
  def to_netmask(decimal) when decimal >= 0 and decimal <= 32 do
    0xffffffff ^^^ ((1 <<< 32 - decimal) - 1)
      |> to_ipaddress
  end

  @doc """
  Turns an erlang-style IPv4 address into a 32 bit decimal integer
  
  ### Examples

      iex> Network.to_ipinteger({192,168,0,45})
      3232235565 
  """
  def to_ipinteger(address) do
    {octet1, octet2, octet3, octet4} = address
    round((octet1*:math.pow(256,3)) + (octet2*:math.pow(256,2)) + (octet3*256) + octet4)
  end

  @doc """
  Determines if two IPv4 addresses with the same mask are on the same subnet
  
  ### Examples

      iex> Network.same_subnet?({192,168,0,45},{192,168,0,85},{255,255,255,0})
      true
  """
  def same_subnet?(ip_address1, ip_address2, netmask) 
    when is_tuple(ip_address1) and is_tuple(ip_address2) and is_tuple(netmask) do 
    (ip_address1 |> to_ipinteger &&& netmask |> to_ipinteger) 
      == (ip_address2 |> to_ipinteger &&& netmask |> to_ipinteger)
  end
 
  @doc """
  Determines if two IPv4 addresses with the same mask are on the same subnet.
  
  ### Examples
  
      iex> Network.same_subnet?("192.168.1.1","192.168.23.254","255.255.255.0")
      false

      iex> Network.same_subnet?("192.168.1.1","192.168.1.254","255.255.255.0")
      true

      iex> Network.same_subnet?("10.22.33.1","10.22.45.254","255.255.0.0")
      true
  """
  def same_subnet?(ip_address1, ip_address2, netmask) 
    when is_binary(ip_address1) and is_binary(ip_address2) and is_binary(netmask) do 
    same_subnet?(ip_address1 |> to_ipaddress, ip_address2 |> to_ipaddress, netmask |> to_ipaddress)
  end

  @doc """
  Determines if an IPv4 address is within a subnet with CIDR notation.
  
  ### Examples

      iex> Network.in_subnet?("192.168.1.50","192.168.1.0/24")
      true
  """
  def in_subnet?(ip_address, network) 
    when is_binary(ip_address) and is_binary(network) do
    [network_ip_address, mask_decimal] = String.split(network,"/")
    same_subnet?(ip_address |> to_ipaddress, network_ip_address |> to_ipaddress, 
       mask_decimal |> String.to_integer |> to_netmask)
  end
  
  @doc """
  Turns an erlang hwaddr (i.e. MAC) into a hex string with separator
  
  ### Examples

      iex> Network.to_macstring([0, 37, 144, 166, 247, 140])
      "00:25:90:a6:f7:8c"
  """
  def to_macstring(hwaddr) do
    hwaddr
      |> Enum.map(&(Hexate.encode(&1,2) <> ":"))
      |> to_string
      |> String.rstrip(?:)
  end

  @doc "Get a list of all the Network interfaces, discarding specified interfaces"
  def get_interfaces() do
    {:ok, interface_data} = :inet.getifaddrs()
    exclusion_list = Application.get_env(:gateway, :exclude_interfaces)
    interface_data 
      |> Enum.filter(fn(x) -> !Enum.member?(exclusion_list, elem(x,0)) end)    
      |> Enum.map(fn(x) -> make_interface_keys_unique(x) end)
  end

  @doc "Check if a named network interface exists. This uses no exclusion list, i.e. all
  interfaces are searched."
  def interface_exists?(interface) do
    {:ok, interface_data} = :inet.getifaddrs()
    interface_data |> Enum.any?(fn(x) -> elem(x,0) == String.to_char_list(interface) end)
  end

  @doc "Parses network interface data, transforming IP addresses and MAC Addresses to 
  string representations. This is most suitable for preparing to send network data
  as JSON or other external representation."
  def parse_interfaces(interfaces) do
    interfaces 
      |> Enum.map(&(parse_interface(&1)))
  end

  @doc """
  Gets the network interface through which a specific network device can be accessed
  This should in theory always only return a single result unless you have a very
  f%%ked-up network. In which case the device can't be routed to anyway.
  """
  def get_device_interface(device_ip_address) do
    interface = get_interfaces
      |> Enum.find(nil, fn(x) ->
            interface_ip = get_interface_attribute(x,:ip_address)
            interface_mask = get_interface_attribute(x,:net_mask)
            if (interface_ip && interface_mask != nil) do
              same_subnet?(interface_ip,device_ip_address, interface_mask) 
            else
              false
            end
          end)

     case interface do
       nil ->
         {:error, :none}
       interface ->
         {:ok, interface}
     end
  end

  @doc """
  Gets an interface attribute (such as IPv4 address) from an interface
  
  Example: get_interface_attribute(interface, :addr)
 
  The interface (originally from :inet.getifaddrs) will look something
  like this:
 
  {'wlan1',
    [flags: [:up, :broadcast, :running, :multicast],
    hwaddr: [16, 254, 237, 31, 86, 13], addr: {172, 16, 0, 184},
    netmask: {255, 255, 255, 0}, broadaddr: {172, 16, 0, 255},
    addr: {65152, 0, 0, 0, 4862, 60927, 65055, 22029},
    netmask: {65535, 65535, 65535, 65535, 0, 0, 0, 0}]
  }

  """
  def get_interface_attribute(interface, key) when is_tuple(interface) do
    {_name,attributes} = interface
    if Keyword.has_key?(attributes, key), do: Keyword.fetch!(attributes,key)
  end

  @doc """
  Gets primary interface. 'Primary' at present, simply means the first interface 
  with an ip address assigned. TODO: Find a better criteria
  """
  def get_primary_interface do
    get_interfaces
      # Filter out interfaces that have no ip address
      |> Enum.filter(fn(x) -> 
           get_interface_attribute(x, :ip_address) != nil
         end)
      # grab the first one
      |> Enum.at(0)
  end

  @doc """
  Gets the primary IP Address of the local system.
  """
  def get_primary_ip_address do
    get_primary_interface
      # Get the ip address as a 4-tuple
      |> get_interface_attribute(:ip_address)
      # Turn the result into a string
      |> to_ipstring
  end

  @doc """
  Gets the primary MAC Address of the local system.
  """
  def get_primary_mac_address do
    get_primary_interface
      # Get the MAC address as a list of decimal integers  
      |> get_interface_attribute(:hwaddr)
      # Turn the result into a string
      |> to_macstring
  end

  @doc "Generates a random ip address in a given range"
  def generate_random_ip(ip_start_range, ip_end_range) do
    start_range = to_ipinteger(ip_start_range)
    end_range = to_ipinteger(ip_end_range)
     
    :random.seed(:os.timestamp)
    random_number = :random.uniform
    random_ip_integer = round((end_range-start_range)*random_number) + start_range
    to_ipaddress(random_ip_integer)
  end

  # Parse a specific interface to transform ipaddr and hwaddr to strings
  # Interface elements are a keyword list which usually contains some duplicate keywords
  defp parse_interface(interface) do
    {interface_name, elements} = interface
    Keyword.keys(elements)
      # Reformat selected values according to their keys
      |> Enum.reduce(elements, fn(x,acc) ->
            {value, list} = Keyword.pop_first(acc,x)
            [ list | [replace_key_value(x, value)]]
            |> List.flatten
          end)
      # Put it into a Map
      |> Enum.into(%{})
      # Add the interface name as a key/value 
      |> Map.put_new("name", to_string(interface_name))
  end

  # Replaces duplicate keys in network interface with unique keys
  # Uses format of value to determine key name
  defp make_interface_keys_unique(interface) do
    {interface_name, elements} = interface
    {interface_name, Keyword.keys(elements)
      |> Enum.reduce(elements, fn(x,acc) ->
            {value, list} = Keyword.pop_first(acc,x)
            [ list | [make_key_unique(x, value)]]
            |> List.flatten
          end)
      }
  end

  # Makes a network interface key unique based on value format
  defp make_key_unique(key, value) do
    case key do
      :addr ->
        case value do
          {_octet1,_,_,_} ->
            {:ip_address, value}
          {_double_octet1, _, _, _, _, _, _, _} ->
            {:ipv6_address, value}
          _->
            {:error, "Invalid IP Address"}
        end
      :netmask ->
         case value do
           {_octet1,_,_,_} ->
             {:net_mask, value}
          {_double_octet1, _, _, _, _, _, _, _} ->
            {:ipv6_net_mask, value}
          _->
            {:error, "Invalid IP Address"}
         end
      _->
        {key, value}
    end
  end

  # Implements the conversion based on key name
  defp replace_key_value(key, value) do
    case key do
      :ip_address ->
        {key, to_ipstring(value)}
      :ipv6_address ->
        {key, to_ipstring(value)}
      :net_mask ->
        {key, to_ipstring(value)}
      :ipv6_net_mask ->
        {key, to_ipstring(value)}
      :broadaddr ->
        {key, to_ipstring(value)}
      :hwaddr ->
        {:mac_address, to_macstring(value)}
      _->
        {key, value}
    end
  end

end
