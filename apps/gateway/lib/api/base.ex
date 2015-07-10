defmodule Gateway.API.Base do
  @moduledoc "Makes actual calls to the API and processes responses"
 
  use HTTPoison.Base
  require Logger

  @doc "Logs warning of API error and generates a standard response"
  def warn(status, body) do
    Logger.warn("HTTP Status Code: #{status} #{(body |> Poison.encode!)}")
    {:error, body} 
  end

  @doc "Logs error from API and generates a standard response"
  def error(reason) do
    Logger.error(reason)
    {:error, reason}
  end

  defp process_url(url) do
    Application.get_env(:gateway, :gateway_api_url) <> url
  end

  # Decode the body into a Map or List of Maps
  defp process_response_body(body) do
    case Poison.decode(body) do
      {:ok, decoded_body} ->
        decoded_body
      {:error, :invalid} ->
        Logger.error("Response was not valid JSON")
        body
      {:error, {:invalid, error}} ->
        Logger.error(error)
        body
    end
  end

  defp process_request_body(body) do
    body
      |> Poison.encode!
  end

  defp process_request_options(options) do
    [hackney: [:insecure]]
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
