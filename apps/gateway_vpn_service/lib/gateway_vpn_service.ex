defmodule GatewayVPNService do
  use Application

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: GatewayVPNService.TaskSupervisor]]),
      worker(Task, [GatewayVPNService.Server, :listen, 
                    [Application.get_env(:gateway_vpn_service, :server_port)]])
    ]

    opts = [strategy: :one_for_one, name: GatewayVPNService.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
