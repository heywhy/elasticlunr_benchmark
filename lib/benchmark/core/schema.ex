defmodule Elasticlunr.Benchmark.Schema do
  @moduledoc false

  alias Elasticlunr.{Index, Pipeline}

  defstruct name: nil, pipeline: nil, fields: %{}

  @type t :: %__MODULE__{
          fields: map(),
          name: binary(),
          pipeline: Pipeline.t()
        }

  @spec field(t(), binary(), keyword()) :: t()
  def field(%__MODULE__{fields: fields} = schema, name, opts \\ []) do
    %{schema | fields: Map.put(fields, name, opts)}
  end

  @spec pipeline(t(), Pipeline.t()) :: t()
  def pipeline(%__MODULE__{} = schema, %Pipeline{} = pipeline) do
    %{schema | pipeline: pipeline}
  end

  @spec to_index(t()) :: Index.t()
  def to_index(%__MODULE__{name: name, pipeline: pipeline, fields: fields}) do
    Index.new(name: name, pipeline: pipeline)
    |> add_fields(fields)
  end

  defp add_fields(index, fields) do
    Enum.reduce(fields, index, fn {field, opts}, index ->
      Index.add_field(index, field, opts)
    end)
  end
end
