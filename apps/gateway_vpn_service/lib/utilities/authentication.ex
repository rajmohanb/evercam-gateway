defmodule GatewayVPNService.Authentication do
  @moduledoc "A temporary mechanism for ensuring validity of requests.
  At present there is simply a fixed token set in the System Environment.
  Since at the moment only the API running at a single location can access
  this service, this will be adequate for the time being. However other network
  based protections are recommended."

  @doc "Checks request token and ensures it is valid"
  def authenticate(request) do
    if request["token"] == token do
      {:ok, request}
    else
      {:error, :authentication_failed}
    end
  end

  def token do
    System.get_env("VPN_SERVICE_TOKEN")
  end

end
