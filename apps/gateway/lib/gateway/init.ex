defmodule Gateway.Init do
  @moduledoc "Loads core configuration, starts main supervision tree and shuts down. If 
  core configuration is not available the Gateway will attempt to register itself with 
  Evercam Gateway API. It will await approval and then download core configuration. If 
  Gateway is already registered but configuration data is for some reason unavailable 
  then it will attempt to download configuration again."

  # TODO: We're passing around the pending gateway and not using it. It occurs to me
  # now that we could actually use this to prevent hijacking of process by giving
  # pending gateway a secret and stop using MAC Address. Must be confident that it 
  # is not a pseudo-secret in this context

  alias Gateway.Init.Registration
  alias Gateway.Init.Configuration
  #alias Gateway.VPN

  use GenServer
  @name __MODULE__
  @registration_interval 10000

  # Client API
  def start_link do
    GenServer.start_link(@name, [], name: @name)
  end

  # Server Callbacks
  def init([]) do
    :erlang.send(self, :load_config)
    {:ok, nil}
  end

  @doc "Tries to load config."
  def handle_info(:load_config, nil) do
    :erlang.send(self, :load_config)
    {:noreply, Configuration.load}
  end

  @doc "Set Application environment with config values. Joins VPN. Terminates Init process."
  def handle_info(:load_config, {:ok, config}) do
    Configuration.set_environment(config)
    #VPN.join
    :erlang.exit(self, :configured)
    {:noreply, nil}
  end

  @doc "Calls registration process since there is no config. TODO: what if config was
  corrupted or deleted?"
  def handle_info(:load_config, {:error, :noconfig}) do
    :erlang.send(self, :register)
    {:noreply, nil}
  end

  @doc "Starts actual registration process by announcing Gateway. TODO: What happens if
  the announce doesn't return a pending gateway record?"
  def handle_info(:register, nil) do
    response = Registration.announce
    :erlang.send(self, :register)
    {:noreply, {:pending, response}}
  end
 
  @doc "Requests token (which will only be issued subject to user approval)"
  def handle_info(:register, {:pending, pending_gateway}) do
    response = Registration.request_token
    :erlang.send(self, :register)
    {:noreply, {:ok, response, pending_gateway}}
  end

  @doc "Gateway is still pending (i.e. no token). Wait and re-request token"
  def handle_info(:register, {:ok, :pending, pending_gateway}) do
    :erlang.send_after(@registration_interval, self, :register)
    {:noreply, {:pending, pending_gateway}}
  end

  @doc "Stores token and triggers self-configuration "
  def handle_info(:register, {:ok, token, _pending_gateway}) do
    # I'm writing this to a file straightaway because right now getting a new one
    # is a bit hairy. TODO: we must have a mechanism for refreshing or recovering
    # a token. Even with a user interaction
    Configuration.write_token(token)

    # As a once off set the token and the gateway id in the system so it can obtain
    # configuration. Later these will be set by the configuration itself
    Configuration.set_environment(%{"gateway_api_token" => Poison.encode!(token),
                                    "gateway_id" => token.gateway_id})
    :erlang.send(self, :get_configuration)
    {:noreply, token}
  end

  @doc "Gets configuration and writes it. Doesn't need token here because token is already in system"
  def handle_info(:get_configuration, _state) do
    config = Registration.get_configuration
    Configuration.write(config)
    :erlang.send(self, :load_config)
    {:noreply, nil}
  end

  @doc false
  def terminate(:configured, _state) do
    Gateway.Supervisor.start_link
    :ok
  end

  @doc false
  def terminate(_reasons, _state) do
    IO.puts "ah hah"
    :ok
  end

end
