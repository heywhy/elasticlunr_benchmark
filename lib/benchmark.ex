defmodule Elasticlunr.Benchmark do
  @moduledoc false
  use Agent

  alias Elasticlunr.Benchmark.{Config, Corpora, Operation, Schema, Suite}

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: :macros
    end
  end

  @spec start() :: :ok
  def start do
    System.at_exit(fn
      0 -> run()
      status -> status
    end)
  end

  defp run do
    opts = Config.get(:cli_options, [])
    grouped = Enum.group_by(all_data(), fn {{mod, _}} -> mod end)

    Enum.each(grouped, fn {_, data} -> Suite.run(data, opts) end)
  end

  defmacro index(name, do: {:__block__, _, [first_expr | exprs]}) do
    body =
      Enum.reduce(exprs, first_expr, fn expr, acc ->
        quote do
          unquote(acc) |> unquote(expr)
        end
      end)

    quote do
      alias Elasticlunr.Benchmark.Schema
      import Schema

      schema =
        %Schema{name: unquote(name)}
        |> unquote(body)

      unquote(__MODULE__).add_schema(__MODULE__, schema)
    end
  end

  defmacro corpora(name, do: {:__block__, _, [first_expr | exprs]}) do
    body =
      Enum.reduce(exprs, first_expr, fn expr, acc ->
        quote do
          unquote(acc) |> unquote(expr)
        end
      end)

    quote do
      alias Elasticlunr.Benchmark.Corpora
      import Corpora

      corpora =
        %Corpora{name: unquote(name)}
        |> unquote(body)

      unquote(__MODULE__).add_corpora(__MODULE__, corpora)
    end
  end

  defmacro operation(name, type, opts \\ []) when type in ~w[bulk search]a do
    quote bind_quoted: [
            name: name,
            type: type,
            opts: opts,
            bench: __MODULE__
          ] do
      bench.add_operation(__MODULE__, Operation.new(name, type, opts))
    end
  end

  @spec add_schema(module(), Schema.t()) :: :ok
  def add_schema(mod, schema) do
    add_data({{mod, schema}})
  end

  @spec add_operation(module(), Operation.t()) :: :ok
  def add_operation(mod, op) do
    add_data({{mod, op}})
  end

  @spec add_corpora(module(), Corpora.t()) :: :ok
  def add_corpora(mod, corpora) do
    add_data({{mod, corpora}})
  end

  defp add_data(data), do: Agent.cast(__MODULE__, &(&1 ++ [data]))

  defp all_data, do: Agent.get(__MODULE__, & &1)
end
