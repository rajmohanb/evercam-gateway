defmodule GatewayVPNService.Crypto do
  import Gateway.Utilities.External
  require Logger

  @doc "Generates a public/private key pair for authentication with the 
  VPN, using OpenSSL"
  def generate_key_pair(gateway_id) when is_integer(gateway_id) do
    command = shell("openssl req -batch -x509 -nodes -days 3650 -newkey rsa:2048" 
                    <> " -keyout #{key_file(gateway_id)}" 
                    <> " -out #{cert_file(gateway_id)}")
    Logger.info(command.out)
    generate_key_pair({:ok, gateway_id, command.status})
  end

  def generate_key_pair({:ok, gateway_id, 0}) do
    {:ok, 
    gateway_id |> key_file |> File.read!, 
    gateway_id |> cert_file |> File.read!} 
  end

  @doc "Generates a random MAC Address. The first two pairs of hex digits 
  are always 00:AC just for consistency with Softether VPN convention."
  def generate_mac_address do
    command = shell("openssl rand -hex 4")
    suffix = Regex.scan(~r/[a-fA-F0-9]{2}/, command.out)
                |> List.flatten
                |> Enum.reduce(fn(x, acc) -> acc <> ":" <> x end)
    {:ok, "00:AC:" <> suffix}
  end
  
  @doc "Stores a certificate in user data directory"
  def store_certificate(certificate, gateway_id) do
    path = certificate_file(gateway_id)
    write_file(certificate, path)
    {:ok, path}
  end

  defp certificate_file(gateway_id) do
    Path.join(get_keys_directory, "gateway#{gateway_id}.pem")
  end

  defp key_file(gateway_id) do
    Path.join(System.tmp_dir, "gateway#{gateway_id}.key")
  end

  defp cert_file(gateway_id) do
    Path.join(System.tmp_dir, "gateway#{gateway_id}.pem")
  end

  defp get_keys_directory do
    key_path = Path.join(System.user_home, Application.get_env(:gateway_vpn_service, :vpn_keys_directory)) 
    if !File.exists?(key_path), do: File.mkdir(key_path)
    key_path
  end

  defp write_file(filename, contents) do
    {:ok, file} = File.open(filename, [:write])
    IO.binwrite(file, contents)
    File.close file
  end

end
