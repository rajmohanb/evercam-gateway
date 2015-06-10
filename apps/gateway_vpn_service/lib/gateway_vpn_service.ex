defmodule GatewayVPNService do
  use Application
  use Supervisor

  @doc false
  def start(_type, _args) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__,[])
    start_workers(sup)
    result
  end

  def start_workers(sup) do
    # Start Redis Connection Pool
    Supervisor.start_child(sup, worker(GatewayVPNService.Redis, []))

    # Start Stash for Routing Rules
    {:ok, rules_stash} = Supervisor.start_child(sup, worker(Gateway.Utilities.Stash,[],id: :rules_stash))

    # Start Sub Supervisor for Rules
    Supervisor.start_child(sup, supervisor(GatewayVPNService.RoutingSupervisor, [rules_stash]))
    
    # Start Task Sub-Supervisor for server connection handling
    Supervisor.start_child(sup, supervisor(Task.Supervisor, [[name: GatewayVPNService.TaskSupervisor]]))
    
    #Start child worker which runs Server
    Supervisor.start_child(sup, worker(Task, [GatewayVPNService.Server, :listen, 
                    [Application.get_env(:gateway_vpn_service, :server_port)]]))
  end

  def init(_) do
    supervise [], [strategy: :one_for_one,  name: GatewayVPNService.Supervisor]
  end

end
