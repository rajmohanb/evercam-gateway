defmodule Gateway.API.Devices do
  @moduledoc "Handles calls to Gateway API for managing LAN Device information."
  alias Gateway.API.Base, as: API

  def post!(gateway_id, devices) do
    API.post!("/gateways/#{gateway_id}/devices", devices).body
  end

end
