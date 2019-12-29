defmodule Alkemist.Assign.Global do
  @moduledoc """
  Creates global assigns based on defaults and options
  """

  @doc """
  Builds a `Keyword` List with global options that need to be available on all pages

  Params:

    * opts - KeywordList with options
    * resource - a Struct or Ecto Struct module
  """
  @default_otp_app :alkemist
  @default_implementation Alkemist

  @default_collection_actions [:new]
  @default_member_actions [
    :show,
    :edit,
    :delete
  ]

  alias Alkemist.{Config, Utils}

  def opts(opts, resource) do
    opts =
      opts
      |> Keyword.put_new(:alkemist_app, @default_otp_app)
      |> Keyword.put_new(:implementation, @default_implementation)

    opts
    |> add_repo()
    |> Keyword.put_new(:collection_actions, @default_collection_actions) # TODO: use implementation for this
    |> Keyword.put_new(:member_actions, @default_member_actions) # TODO: use implementation
    |> Keyword.put_new(:singular_name, Utils.singular_name(resource))
    |> Keyword.put_new(:plural_name, Utils.plural_name(resource))
    |> Keyword.put_new(:route_params, [])
  end

  defp add_repo(opts) do
    Keyword.put_new(opts, :repo, Config.repo(opts[:alkemist_app], opts[:implementation]))
  end
end
