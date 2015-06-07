defmodule GatewayVPNService.Utilities.Netstring do

  @doc "Takes in a NetString and returns {:ok, string1}"
  def read(netstring) when is_binary(netstring) do
    case Regex.run(~r/^([0-9]+):(.+)/, netstring, capture: :all_but_first) do
      nil ->
        {:error, :bad_header}
      match ->
        read_match(match)
    end
  end

  @doc "Takes in a string and returns {:ok, netstring}"
  def write(string) when is_binary(string) do
    {:ok, "#{byte_size(string)}:#{string},"} 
  end

  defp read_match([size_string, string]) do
    size = String.to_integer(size_string)
    if size >= byte_size(string) do
      {:error, :bad_length}
    else
      read_match({size, string})
    end
  end

  defp read_match({size, string}) do
    if binary_part(string, size, 1) == "," do
      {:ok, size, binary_part(string, 0, (size)) }
    else
      {:error, :missing_delimiter}
    end
  end

end
