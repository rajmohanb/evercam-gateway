defmodule GatewayVPNService.Redis do
  @moduledoc "A very primitive implementation of Redis with connection pool.
  TODO: Would make a lot of sense to flesh this out into two modules and make
  better use of Exredis."
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    pool_options = [
      {:name, {:local, :redis_pool}},
      {:worker_module, Exredis}, 
      {:size, 5},
      {:max_overflow, 10}
      ]
    config = Exredis.ConnectionString.parse(System.get_env("REDIS_URL"))
    exredis_args = [
      {:host, config.host},
      {:port, config.port},
      {:database, config.db}
      ]
    children = [
      :poolboy.child_spec( :redis_pool, pool_options, exredis_args)
      ]
    supervise(children, strategy: :one_for_one)
  end

  # a redis query transaction function
  def query(args) do
    {:ok, :poolboy.transaction(:redis_pool, fn(worker) -> Exredis.query(worker, args) end)}
  end

end
