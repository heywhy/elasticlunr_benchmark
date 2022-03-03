defmodule Elasticlunr.Benchmark.Suite do
  @moduledoc false

  alias Benchee.Formatter
  alias Elasticlunr.IndexManager
  alias Elasticlunr.Benchmark.{Config, Corpora, CorporaLoader, Operation, Schema}

  @spec run(list(tuple()), keyword()) :: :ok
  def run(args, opts) do
    schemas = filter_suite_type(args, Schema)
    corpora = filter_suite_type(args, Corpora)
    operations = filter_suite_type(args, Operation)

    inputs = schemas_to_inputs(schemas)

    setup_suite(schemas, corpora, opts)

    execute_suite(inputs, operations, corpora)

    cleanup_suite(schemas)
  end

  defp execute_suite(inputs, operations, [corpora]) do
    formatter =
      Config.get(:cli_options)
      |> Keyword.get(:formatter, Benchee.Formatters.Console)

    config = [
      memory_time: 2,
      inputs: inputs,
      formatters: [formatter],
      before_scenario: &[index: &1, corpora: corpora]
    ]

    config
    |> Benchee.init()
    |> Benchee.system()
    |> add_benchmarking_jobs(operations)
    |> Benchee.collect()
    |> Benchee.statistics()
    |> Benchee.load()
    |> Benchee.relative_statistics()
    |> Formatter.output()
  end

  defp setup_suite(schemas, corpora, opts) do
    Enum.each(schemas, fn schema ->
      index = Schema.to_index(schema)
      {:ok, _} = IndexManager.save(index)
    end)

    Enum.each(corpora, &CorporaLoader.process(&1, opts))
  end

  defp cleanup_suite(schemas) do
    Enum.each(schemas, fn schema ->
      schema.name
      |> IndexManager.get()
      |> IndexManager.remove()
    end)
  end

  defp add_benchmarking_jobs(suite, operations) do
    Enum.reduce(operations, suite, fn %{name: name} = op, suite_acc ->
      callback = op_to_benchmark_callback(op)
      Benchee.benchmark(suite_acc, name, callback)
    end)
  end

  defp op_to_benchmark_callback(operation) do
    fn opts -> Operation.apply(operation, opts) end
  end

  defp schemas_to_inputs(schemas) do
    Enum.map(schemas, &{&1.name, &1.name}) |> Enum.into(%{})
  end

  defp filter_suite_type(args, mod) do
    Enum.filter(args, fn
      {{_, %^mod{}}} -> true
      _ -> false
    end)
    |> Enum.map(fn {{_, type}} -> type end)
  end
end
