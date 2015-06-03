defmodule Gateway.API.Devices do
  @moduledoc "Handles calls to Gateway API for managing LAN Device information."
  alias Gateway.API.Base, as: API

  def post(gateway_id, devices) do
    case API.post("/gateways/#{gateway_id}/devices", devices) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        API.warn(status, body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        API.error(reason)
    end
  end

end
