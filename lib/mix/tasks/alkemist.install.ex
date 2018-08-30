defmodule Mix.Tasks.Alkemist.Install do
  @moduledoc """
  Install Alkemist assets and supporting files.
  You can skip this if you want to provide your own Layout.

    mix alkemist.install
  """
  # TODO: provide option --static-path to set a variable path
  use Mix.Task

  @shortdoc "Installs the supporting files for Alkemist"
  def run(_) do
    copy_assets()
  end

  defp copy_assets do
    IO.puts("creating assets")
    base_path = Path.join(~w(priv static))

    copy_vendor(base_path, "css", "alkemist.css")
    copy_vendor(base_path, "js", "alkemist.js")
    copy_vendor_r(base_path, "fonts")
  end

  defp copy_vendor(base_path, path, filename) do
    File.cp(
      Path.join([get_package_path(), base_path, path, filename]),
      Path.join([File.cwd!(), "priv", "static", path, filename])
    )
  end

  defp copy_vendor_r(base_path, path) do
    File.cp_r(
      Path.join([get_package_path(), base_path, path]),
      Path.join([File.cwd!(), "priv", "static", path])
    )
  end

  defp get_package_path do
    __ENV__.file
    |> Path.dirname()
    |> String.split("/lib/mix/tasks")
    |> hd()
  end
end
