defmodule Elasticlunr.Benchmark.Decompressor do
  @moduledoc false

  @spec decompress(binary(), binary()) :: :ok
  def decompress(file, directory) do
    case Path.extname(file) do
      ".bz2" ->
        args = ["bunzip2", "--force", "--stdout"]
        decompress_cmd(directory, file, args)
    end
  end

  defp decompress_cmd(directory, file, args) do
    [bin | args] = args

    file_without_ext =
      Path.basename(file)
      |> String.replace(Path.extname(file), "")

    stream =
      Path.join(directory, file_without_ext)
      |> File.stream!()

    {%File.Stream{}, 0} = System.cmd(bin, args ++ [file], into: stream)
    :ok
  end
end
