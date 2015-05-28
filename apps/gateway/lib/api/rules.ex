defmodule Gateway.API.Rules do 
  @moduledoc "Handles calls to Gateway API for obtaining forwarding rule information."
  alias Gateway.API.Base, as: API

  @doc "Gets all the forwarding rules for a specific Gateway"
  def get!(gateway_id) do
    API.get!("/gateways/#{gateway_id}/rules").body
  end
 
  @doc "Gets all the forwarding rules for a specific Gateway"
  def get(gateway_id) do
    {:ok, response} = API.get("/gateways/#{gateway_id}/rules")
    {:ok, response.body}
  end

end
