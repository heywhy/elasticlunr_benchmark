defmodule Elasticlunr.Benchmark.Operation do
  @moduledoc false

  alias Elasticlunr.Benchmark.CorporaLoader
  alias Elasticlunr.{Index, IndexManager}

  defstruct ~w[name type options]a

  @type t :: %__MODULE__{
          name: atom(),
          type: atom(),
          options: keyword() | map()
        }

  @docs_table :docs

  @spec new(atom(), atom(), keyword()) :: t()
  def new(name, type, options \\ []) do
    struct!(__MODULE__, name: name, type: type, options: options)
  end

  @spec apply(t(), keyword()) :: any()
  def apply(%__MODULE__{type: :bulk, options: options}, index: index, corpora: corpora) do
    index = IndexManager.get(index)

    unless Enum.member?(:ets.all(), @docs_table) do
      :ets.new(@docs_table, ~w[set named_table public]a)
    end

    :ok =
      CorporaLoader.stream(corpora)
      |> Enum.each(fn stream ->
        Stream.map(stream, fn str ->
          case :ets.lookup(@docs_table, str) do
            [] ->
              {:ok, data} = Jason.decode(str)
              data = Map.put_new_lazy(data, "id", &FlakeId.get/0)
              true = :ets.insert(@docs_table, {str, data})
              data

            [{^str, data}] ->
              data
          end
        end)
        |> Stream.chunk_every(options[:bulk_size])
        |> Stream.each(fn documents ->
          index
          |> Index.add_documents(documents, options)
          |> IndexManager.update()
        end)
        |> Stream.run()
      end)
  end

  def apply(%__MODULE__{type: :search, options: query}, index: index, corpora: _corpora)
      when is_map(query) do
    index = IndexManager.get(index)

    Index.search(index, query)
  end
end
