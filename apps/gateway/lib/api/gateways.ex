defmodule Gateway.API.Gateways do
  @moduledoc "Handles calls to Gateway API for announcing Gateways, 
  obtaining authentication and configuration and obtaining Gateway data."
  alias Gateway.API.Base, as: API

  # Pending Gateways / Registration endpoints

  def post!(request_body) do
    API.post!("/gateways", request_body).body
  end
  
  def get_token!(params) do
    API.get!("/gateways/#{params[:mac_address]}/token").body
  end

  # Authenticated Endpoints
  def get_configuration!(params) do
    API.get!("/gateways/#{params[:gateway_id]}/configuration").body
  end


end
