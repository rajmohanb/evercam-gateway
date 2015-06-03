defmodule Gateway.API.Gateways do
  @moduledoc "Handles calls to Gateway API for announcing Gateways, 
  obtaining authentication and configuration and obtaining Gateway data."
  alias Gateway.API.Base, as: API

  # Pending Gateways / Registration endpoints

  def post(request_body) do
    case API.post("/gateways", request_body) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} -> 
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        API.warn(status, body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        API.error(reason)
    end
  end
  
  def get_token(mac_address, params) do
    case API.get("/gateways/#{mac_address}/token",[], params: params) do
       {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        API.warn(status, body)    
      {:error, %HTTPoison.Error{reason: reason}} ->
        API.error(reason)
    end
  end

  # Authenticated Endpoints
 
  def get_configuration(params) do
    case API.get("/gateways/#{params[:gateway_id]}/configuration") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        API.warn(status, body)    
      {:error, %HTTPoison.Error{reason: reason}} ->
        API.error(reason)
    end
  end

end
