defmodule Alkemist.Assign do
  @moduledoc """
  Provides helper functions for generic CRUD assigns
  """
  @callback assigns(resource :: any(), opts :: keyword(), params :: map()) :: keyword()
  @callback assigns(resource :: any(), opts :: keyword()) :: keyword()
  @callback assigns(resource :: any()) :: keyword()
  @callback default_opts(keyword(), module()) :: keyword()

  @optional_callbacks assigns: 1, assigns: 2, assigns: 3

  @doc """
  Creates the default assigns for a controller index action.
  """
  @deprecated "Use Alkemist.Assign.Index.assigns/3 instead"
  def index_assigns(params, resource, opts \\ []) do
    Alkemist.Assign.Index.assigns(resource, opts, params)
  end

  @doc """
  Creates all the necessary values for the CSV generation
  """
  @deprecated "Use Alkemist.Assign.Export.assigns/3 instead"
  def csv_assigns(params, resource, opts \\ []) do
    Alkemist.Assign.Export.assigns(resource, opts, params)
  end

  @doc """
  Creates the view assigns for the new and edit actions
  """
  @deprecated "Use `Alkemist.Assign.Form.assigns/2` instead"
  def form_assigns(resource, opts \\ []) do
    Alkemist.Assign.Form.assigns(resource, opts)
  end

  @doc """
  Creates the assigns for the show view
  """
  @deprecated "Use `Alkemist.Assign.Show.assigns/2` instead"
  def show_assigns(resource, opts \\ []) do
    Alkemist.Assign.Show.assigns(resource, opts)
  end

end
