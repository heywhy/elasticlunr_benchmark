defmodule Elasticlunr.Benchmark.Config do
  @moduledoc false

  @otp_app :elasticlunr_benchmark

  @spec put(atom(), any()) :: :ok
  def put(key, value) do
    Application.put_env(@otp_app, key, value)
  end

  @spec get(atom(), any()) :: any()
  def get(key, default \\ nil) do
    Application.get_env(@otp_app, key, default)
  end
end
