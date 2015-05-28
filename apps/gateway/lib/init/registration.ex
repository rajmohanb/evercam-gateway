defmodule Gateway.Init.Registration do
  alias Gateway.API.Gateways
  alias Gateway.Init.Network

  @doc "Announces Gateway to Evercam Gateway API"
  def announce do
    Gateways.post!(%{:mac_address => Network.get_primary_mac_address})
  end

  @doc "Requests a token from the Evercam Gateway API"
  def request_token do
    response = Gateways.get_token!(%{:mac_address => Network.get_primary_mac_address})

    # TODO: This is shit. Find the right way. May involve adjusting API.
    case response do
      %{"error" => _} ->
        :pending
      _ ->
        response
    end
  end

  @doc "Gets configuration from Evercam Gateway API"
  def get_configuration(gateway_id) do
    Gateways.get_configuration(gateway_id)
  end

end
