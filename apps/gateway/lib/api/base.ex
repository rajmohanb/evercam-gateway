defmodule Gateway.API.Base do
  @moduledoc "Makes actual calls to the API and processes responses"
 
  use HTTPoison.Base

  defp process_url(url) do
    Application.get_env(:gateway, :gateway_api_url) <> url
  end

  # Decode the body into a Map or List of Maps
  defp process_response_body(body) do
    body
      |> Poison.decode!
  end

  defp process_request_body(body) do
    body
      |> Poison.encode!
  end

  # Add authorization header to all calls. It can be ignored by those 
  # that don't require it. If the gateway doesn't yet have a token then
  # it will also obviously have no effect
  defp process_request_headers(headers) do
    token = Application.get_env(:gateway, :gateway_api_token)
    if is_map(token) do
      [{"Authorization", "Token " <> token["token"]}]
    else
      []
    end
  end

end
