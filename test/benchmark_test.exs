defmodule Elasticlunr.BenchmarkTest do
  use ExUnit.Case

  alias Elasticlunr.Benchmark
  alias Elasticlunr.Benchmark.Track

  import Elasticlunr.Benchmark.TestFixture

  describe "processing track config" do
    test "returns right config" do
      config = Benchmark.track_config(tracks_path(), "sample")

      assert {:ok, %Track{description: "sample track"}} = config
    end
  end
end
