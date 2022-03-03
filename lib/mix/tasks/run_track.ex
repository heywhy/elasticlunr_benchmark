defmodule Mix.Tasks.Run.Track do
  @moduledoc false
  use Mix.Task

  alias Elasticlunr.Benchmark
  alias Elasticlunr.Benchmark.Config

  @requirements ["app.config", "app.start"]

  @switches [
    dir: :string,
    report: :string,
    cache_dir: :string,
    log_level: :string,
    no_compile: :boolean
  ]

  @aliases [d: :dir]

  @helper_path "benchmarks/benchmarks_helper.exs"

  @impl Mix.Task
  def run(args) do
    {paths, options, no_compile} =
      parse_options(args)
      |> normalize_options()

    prepare_mix_project(no_compile)

    Config.put(:cli_options, options)
    :ok = Logger.configure(level: Keyword.get(options, :log_level, :info))

    load_track_files(paths)
  end

  defp parse_options(args) do
    case OptionParser.parse(args, strict: @switches, aliases: @aliases) do
      {opts, paths, []} ->
        {paths, opts}

      {_, _, [{opt, nil} | _]} ->
        Mix.raise("Invalid option: #{opt}")

      {_, _, [{opt, val} | _]} ->
        Mix.raise("Invalid option: #{opt}=#{val}")
    end
  end

  defp prepare_mix_project(no_compile) do
    # Set up the target project's paths
    Mix.Project.get!()
    args = ["--no-start"]

    args =
      case no_compile do
        true -> args ++ ["--no-compile"]
        _ -> args
      end

    Mix.Task.run("app.start", args)
  end

  defp load_track_files([]) do
    (Path.wildcard("benchmarks/**/*_track.exs") ++
       Path.wildcard("apps/**/benchmarks/**/*_track.exs"))
    |> do_load_track_files
  end

  defp load_track_files(paths) do
    Enum.flat_map(paths, &Path.wildcard/1)
    |> do_load_track_files
  end

  defp do_load_track_files([]), do: nil

  defp do_load_track_files(files) do
    load_benchmarks_helper()
    Kernel.ParallelCompiler.require(files)
  end

  defp load_benchmarks_helper() do
    if File.exists?(@helper_path) do
      Code.require_file(@helper_path)
    else
      :ok = Benchmark.start()
    end
  end

  defp normalize_options({paths, opts}) do
    {no_compile, opts} =
      Enum.reduce(opts, %{}, &normalize_option/2)
      |> Map.pop(:no_compile)

    {paths, Map.to_list(opts), no_compile}
  end

  defp normalize_option({:cache_dir, dir}, acc) do
    Map.put(acc, :cache_dir, Path.absname(dir))
  end

  defp normalize_option({:log_level, level}, acc) do
    Map.put(acc, :log_level, String.to_atom(level))
  end

  defp normalize_option({:report, "html"}, acc) do
    Map.put(acc, :formatter, Benchee.Formatters.HTML)
  end

  defp normalize_option({key, value}, acc) do
    Map.put(acc, key, value)
  end
end
