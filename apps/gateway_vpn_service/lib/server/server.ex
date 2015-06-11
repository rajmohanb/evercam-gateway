defmodule GatewayVPNService.Server do
  @moduledoc "Listens for incoming requests, authenticates them, passes them to appropriate handler
  and passes back response."
  require Logger
  require Application
  alias GatewayVPNService.Server.Request
  alias GatewayVPNService.Server.Response

  @doc """
  Starts accepting connections on the given `port`.
  """
  def listen(port) do
    :ssl.start
    {:ok, socket} = :gen_tcp.listen(port,
                      [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    accept(socket)
  end
 
  # accepts a connection. If successful kicks off handling process
  # and waits to accept next connection on the same socket
  defp accept(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        case :ssl.ssl_accept(client, Application.get_env(:gateway_vpn_service, :ssl_options)) do
          {:ok, ssl_client} ->
            {:ok, pid} = Task.Supervisor.start_child(GatewayVPNService.TaskSupervisor, fn -> serve(ssl_client) end)
            :ssl.controlling_process(ssl_client, pid)
            accept(socket)
          {:error, :closed} ->
            accept(socket)
          _ ->
            Logger.info("Error in establishing connection...")
        end
      {:error, :closed} -> accept(socket)
      {:error, _} -> { :stop, :error, [] }
    end
  end

  defp serve(socket) do
    case Request.handle(socket) do
      {:ok, request} ->
        Logger.info("Processing request...")
        request |> Response.create |> Response.send(socket)
      {:error, :authentication_failed} ->
        Logger.info("Authentication failed for request")
        Response.send_failure(:authentication_failed)
      {:error, {:parsing_failed, reason}} ->
        Logger.info("Parsing Failed: #{reason}")
        Response.send_failure(:parsing_failed)
      _ ->
        :ssl.close(socket)
    end
  end

end
