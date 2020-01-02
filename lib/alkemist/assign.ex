defmodule Alkemist.Assign do
  @moduledoc """
  Generic Behaviour for Assign modules
  """
  @callback assigns(implementation :: module(), resource :: any(), opts :: keyword(), params :: map()) :: keyword()
  @callback assigns(implementation :: module(), resource :: any(), opts :: keyword()) :: keyword()
  @callback assigns(implementation :: module(), resource :: any()) :: keyword()
  @callback default_opts(opts :: keyword(), implementation :: module(), resource :: module()) :: keyword()

  @optional_callbacks assigns: 2, assigns: 3, assigns: 4

end
