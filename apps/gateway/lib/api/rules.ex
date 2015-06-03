defmodule Gateway.API.Rules do 
  @moduledoc "Handles calls to Gateway API for obtaining forwarding rule information."
  alias Gateway.API.Base, as: API

  @doc "Gets all the forwarding rules for a specific Gateway"
  def get(gateway_id) do
    case API.get("/gateways/#{gateway_id}/rules") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        API.warn(status, body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        API.error(reason)
    end
  end
 
end
