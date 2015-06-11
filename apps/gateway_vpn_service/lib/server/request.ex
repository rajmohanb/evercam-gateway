defmodule GatewayVPNService.Server.Request do
  require Logger
  alias GatewayVPNService.Utilities.Netstring
  alias GatewayVPNService.Authentication

  @doc "Reads entire incoming request and authenticates it"
  def handle(socket) do
    Logger.info("Handling incoming request...")
    case read_all(socket) do
      {:ok, request} ->
        process(request)
      {:error, reason} ->
        {:error, {:read, reason}}
    end
  end

  defp read_all(socket, alldata \\ "") do
    Logger.info("Reading data...")
    case :ssl.recv(socket, 0) do
      {:ok, data} ->
        alldata = alldata<>data
        case alldata |> Netstring.read do
          {:ok, size, request} ->
            {:ok, request}
          {:error, _} ->
            read_all(socket, alldata <> data)
        end
      {:error, :closed} ->
        Logger.info("Connection closed.")
        {:error, :closed}
      {:error, reason} ->
        Logger.error("Error reading data from socket: #{reason}")
        {:error, reason}
    end
  end

  defp process(request) when is_binary(request) do 
    request |> Poison.Parser.parse |> process
  end

  defp process({:ok, request}) when is_map(request) do
    request |> Authentication.authenticate 
  end

  defp process({:error, reason}) do
    {:error, {:parsing_failed, reason}}
  end

end
