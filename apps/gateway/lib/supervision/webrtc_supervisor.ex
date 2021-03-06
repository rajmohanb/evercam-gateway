defmodule Gateway.WebRTCSupervisor do
  use Supervisor
  require Logger

  def start_link(init_params) do
    result = { :ok, sup } = Supervisor.start_link(__MODULE__, [init_params])
    start_streamer(sup, init_params)
    start_relay(sup, init_params)
    result
  end

  def main(argv) do
    WebrtcGw.Streaming.Stream.start
    WebrtcGw.Relay.Relay.start
  end

  defp start_streamer(sup, init_params) do
    { :ok, streamer } = Supervisor.start_child(sup, worker(WebrtcGw.Streaming.Stream, init_params))
  end

  defp start_relay(sup, init_params) do
    { :ok, relay } = Supervisor.start_child(sup, worker(WebrtcGw.Relay.Relay, init_params))
  end

  def init(_) do
    supervise [], strategy: :one_for_one
  end
end
