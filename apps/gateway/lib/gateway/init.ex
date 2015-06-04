defmodule Gateway.Init do
  @moduledoc "Loads core configuration, starts main supervision tree and shuts down. If 
  core configuration is not available the Gateway will attempt to register itself with 
  Evercam Gateway API. It will await approval and then download core configuration. If 
  Gateway is already registered but configuration data is for some reason unavailable 
  then it will attempt to download configuration again."

  alias Gateway.Init.Registration
  alias Gateway.Init.Configuration
  alias Gateway.VPN
  require Logger

  use GenServer
  @name __MODULE__
  @registration_interval 10000

  # Client API
  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  @doc "Tries to load config."
  def load_config do
    Logger.info "Attempting to load configuration from file"
    load_config(Configuration.load)
  end

  @doc "Set Application environment with config values. Joins VPN. Terminates Init process."
  def load_config({:ok, config}) do
    Configuration.set_environment(config)
    VPN.join
    {:ok, :configured}
  end

  @doc "If there is no config, tries to download one from Gateway API."
  def load_config({:error, :noconfig}) do
    case Configuration.load_token do
      {:ok, token} ->
        # FIXME: This is not a satisfactory way of solving the got api, got no config problem
        Configuration.set_environment(%{"gateway_api_token" => token,
                                    "gateway_id" => token["gateway_id"]})  
        get_config
      _ ->
        register
    end
  end

  @doc "Starts actual registration process by announcing Gateway. TODO: What happens if
  the announce doesn't return a pending gateway record?"
  def register do
    response = Registration.announce
    if is_map(response), do: Registration.retain_m2m_secret(response)
    register({:pending, response})
  end
 
  @doc "Requests token (which will only be issued subject to user approval)"
  def register({:pending, pending_gateway}) do
    response = Registration.request_token
    register({:ok, response, pending_gateway})
  end

  @doc "Gateway is still pending (i.e. no token). Wait and re-request token"
  def register({:ok, :pending, pending_gateway}) do
    Logger.info("Waiting to re-request token")
    {:error, :awaiting_authentication}
  end

  @doc "Stores token and triggers self-configuration "
  def register({:ok, token, _pending_gateway}) do
    # I'm writing this to a file straightaway because right now getting a new one
    # is a bit hairy. TODO: we must have a mechanism for refreshing or recovering
    # a token. Even with a user interaction
    Configuration.write_token(token)

    # As a once off set the token and the gateway id in the system so it can obtain
    # configuration. Later these will be set by the configuration itself
    token_map = Poison.encode!(token)
    Configuration.set_environment(%{"gateway_api_token" => token_map,
                                    "gateway_id" => token["gateway_id"]})
    get_config
  end

  @doc "Gets configuration and writes it."
  def get_config do
    case Registration.get_configuration do
      {:ok, config} ->
        if Map.has_key?(config, "gateway_id"), do: Configuration.write(config)
      {:error,_} ->
    end
    load_config
  end

  # Server Callbacks
  @doc false
  def init([]) do
    :erlang.send(self, :load_config)
    {:ok, nil}
  end

  @doc false
  def handle_info(:load_config, _state) do
    case load_config do
      {:ok, :configured} ->
        Logger.info("Configuration complete")
        Gateway.Supervisor.start_link
      {:error, :awaiting_authentication} ->
        :erlang.send_after(@registration_interval, self, :load_config)
      _ ->
        Logger.info("Unexpected outcome")
    end
    {:noreply, nil}
  end

  @doc false
  def terminate(_reasons, _state) do
    Logger.info("Initialisation process terminating...")
  end

end
