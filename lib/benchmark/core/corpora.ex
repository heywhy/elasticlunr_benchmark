defmodule Elasticlunr.Benchmark.Corpora do
  @moduledoc false

  defstruct ~w[name url documents]a

  @type t :: %__MODULE__{
          name: binary(),
          url: binary(),
          documents: list(binary())
        }

  @spec url(t(), binary()) :: t()
  def url(%__MODULE__{} = corpora, url), do: %{corpora | url: url}

  @spec document(t(), keyword()) :: t()
  def document(%__MODULE__{url: url, documents: documents} = corpora, opts) do
    source_file = Keyword.get(opts, :source_file)
    document_count = Keyword.get(opts, :document_count, 0)

    document = %{
      archive: source_file,
      document_count: document_count,
      file: Path.rootname(source_file),
      base_url: URI.to_string(URI.new!("#{url}/#{source_file}"))
    }

    %{corpora | documents: append_document(documents, document)}
  end

  defp append_document(nil, document), do: [document]
  defp append_document(documents, document), do: documents ++ [document]
end
