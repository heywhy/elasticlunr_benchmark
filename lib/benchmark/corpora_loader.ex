defmodule Elasticlunr.Benchmark.CorporaLoader do
  @moduledoc false
  use GenServer

  alias Elasticlunr.Benchmark.{Corpora, Decompressor, Downloader}

  require Logger

  def init(_), do: {:ok, %{}}

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec is_locally_available(String.t()) :: boolean()
  def is_locally_available(file), do: File.exists?(file)

  @spec stream(Corpora.t()) :: Enumerable.t()
  def stream(%Corpora{} = corpora) do
    get_documents(corpora.name)
    |> Enum.map(&File.stream!/1)
  end

  @spec process(Corpora.t(), keyword()) :: :ok
  def process(%Corpora{name: name, documents: documents}, opts) do
    cache_dir =
      opts
      |> Keyword.get_lazy(:cache_dir, &System.tmp_dir!/0)
      |> Path.join(name)

    :ok = prepare_documents(documents, name, cache_dir)
  end

  defp prepare_documents([], _corpora, _cache_dir), do: :ok

  defp prepare_documents([document | documents], corpora, cache_dir) do
    %{file: file, archive: archive, base_url: base_url} = document
    file_path = Path.join(cache_dir, file)
    archive_path = Path.join(cache_dir, archive)

    cond do
      is_locally_available(file_path) ->
        add_document(corpora, file_path)
        prepare_documents(documents, corpora, cache_dir)

      is_locally_available(archive_path) ->
        Logger.info("decompressing #{archive_path} to #{file_path}")
        :ok = decompress_archive(archive_path, file_path)
        prepare_documents(documents, corpora, cache_dir)

      true ->
        Logger.info("downloading #{archive_path} from #{base_url}")
        {:ok, _} = download_file(base_url, archive_path)
        prepare_documents([document] ++ documents, corpora, cache_dir)
    end
  end

  defp add_document(corpora, file_path) do
    GenServer.call(__MODULE__, {:add_document, corpora, file_path})
  end

  defp get_documents(corpora), do: GenServer.call(__MODULE__, {:get_documents, corpora})

  def handle_call({:add_document, corpora, path}, _from, state) do
    paths = Map.get(state, corpora, []) ++ [path]

    {:reply, :ok, Map.put(state, corpora, Enum.uniq(paths))}
  end

  def handle_call({:get_documents, corpora}, _from, state) do
    {:reply, Map.get(state, corpora, []), state}
  end

  defp decompress_archive(archive_path, file_path) do
    directory = Path.dirname(file_path)
    Decompressor.decompress(archive_path, directory)
  end

  defp download_file(url, archive_path) do
    Downloader.download(url, path: archive_path)
  end
end
