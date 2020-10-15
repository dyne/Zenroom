defmodule Mix.Tasks.Compile.Zenroom do
  def run(_) do
    {result, _error_code} = System.cmd("make", ["zenroom.so"], stderr_to_stdout: true)
    IO.binwrite result
    :ok
  end
end

defmodule Zenroom.Mixfile do
  use Mix.Project

  @version "1.2.0"

  def project do
    [app: :zenroom,
     version: @version,
     elixir: ">= 0.14.3 and < 2.0.0",
     compilers: [:zenroom, :elixir, :app]]
  end

  def application do
    []
  end
end
