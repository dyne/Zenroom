defmodule Zenroom do
  @moduledoc """
  Zenroom crypto VM execution of Zencode scripts
  """

  @on_load { :init, 0 }

  app = Mix.Project.config[:app]

  def init do
    path = :filename.join(:code.priv_dir(unquote(app)), 'zenroom')
    :ok = :erlang.load_nif(path, 0)
  end

  @doc ~S"""
  Executes a Zencode script

    iex> Zenroom.zencode_exec "Given nothing\nWhen I create a random 'password'\nThen print the 'password'"
    "{ "password": "WED0J2HFDdCINLodzxCDkLzkOpnqJel84PjYrrEU112Rptl1o-6459uFxi07XInMz05sggBxLywKQECNaS0aHw" }"

  """
  @spec zencode_exec(script :: String.t) :: String.t
  @spec zencode_exec(script :: String.t, conf :: String.t, keys :: String.t, data :: String.t) :: String.t

  def zencode_exec(script, conf, keys, data \\ [])

  def zencode_exec(_, _) do
    exit(:nif_library_not_loaded)
  end
end
