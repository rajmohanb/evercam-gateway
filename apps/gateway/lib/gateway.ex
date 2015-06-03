defmodule Gateway do
  use Supervisor

  @doc "Starts Gateway Initialisation process."
  def start(_type, _args) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    child_processes = [worker(Gateway.Init, [], restart: :transient)]
    supervise child_processes, strategy: :one_for_one
  end

end
