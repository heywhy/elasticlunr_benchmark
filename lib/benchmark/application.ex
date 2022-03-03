defmodule Elasticlunr.Benchmark.Application do
  use Application

  alias Elasticlunr.Benchmark

  def start(_type, _args) do
    children = [
      Benchmark,
      Benchmark.CorporaLoader
    ]

    opts = [strategy: :one_for_one, name: Elasticlunr.Benchmark.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
