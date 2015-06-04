defmodule Gateway.Init.Registration do
  alias Gateway.API.Gateways
  alias Gateway.Init.Configuration

  @c "Announces Gateway to Evercam Gateway API"
  def announce do
    request_body = %{:mac_address => Configuration.get_primary_mac_address,
                     :m2m_secret => Configuration.load_m2m_secret}
    case Gateways.post(request_body) do
      {:ok, body} ->
        body
      {:error, _} ->
        nil
    end
  end

  @doc "Requests a token from the Evercam Gateway API"
  def request_token do
    params =  %{:m2m_secret => Configuration.load_m2m_secret}
    case Gateways.get_token(Configuration.get_primary_mac_address, params) do
      {:ok, body} ->
        body
      {:error, _} ->
        :pending
    end
  end

  @doc "Gets configuration from Evercam Gateway API"
  def get_configuration do
    gateway_id = Application.get_env(:gateway, :gateway_id)
    Gateways.get_configuration(%{:gateway_id=>gateway_id})
  end

  @doc "If the API returned an m2m secret with response then we must retain it permanently
  as it can never be recovered"
  def retain_m2m_secret(pending_gateway) when is_map(pending_gateway) do
    if Map.has_key?(pending_gateway, "m2m_secret") do
      Configuration.write_m2m_secret(pending_gateway["m2m_secret"])
    end
  end

end
