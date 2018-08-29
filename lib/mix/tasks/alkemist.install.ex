defmodule Mix.Tasks.Alkemist.Install do
  @moduledoc """
  Install Alkemist assets and supporting files.
  You can skip this if you want to provide your own Layout.

    mix alkemist.install
  """

  use Mix.Task

  @shortdoc "Installs the supporting files for Alkemist"
  def run(args) do
    IO.inspect(args)
    copy_assets()
  end

  defp copy_assets do
    IO.puts("Installing assets")
  end
end
