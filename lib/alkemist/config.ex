defmodule Alkemist.Config do
  @moduledoc """
  Alkemist's configuration, validated with `NimbleOptions` and memoised per OTP app.

  Alkemist reads `config :<otp_app>, Alkemist, [...]` where `otp_app` is the option given
  to `use Alkemist.Controller, otp_app: :my_app` (default `:alkemist`). Each app can thus
  carry its own configuration.

  ## Options

  #{NimbleOptions.docs(Alkemist.Config.Schema.schema())}

  (Schema module: Alkemist.Config.Schema, internal.)

  Unknown keys raise at first use. The keys removed in 3.0 (`web_interface`,
  `json_library`, `router_helpers`, `route_prefix`) raise with a pointer to their
  replacement. Call `validate!/1` from your application start to fail at boot instead.
  """

  alias Alkemist.Config.Schema

  @removed %{
    web_interface: "it named the menu file cache, which no longer exists (menus come from the router)",
    json_library: "it encoded the menu file cache, which no longer exists",
    router_helpers: "paths are derived from the router by Alkemist.Routes",
    route_prefix: "paths are derived from the router by Alkemist.Routes",
    views: "templates are Phoenix components now; override them in a module that `use Alkemist.Theme` and set `theme:`",
    decorators:
      "rendering hooks are theme callbacks now (`value/1`, `row_class/2`, `member_actions/1`, `filter_field/1`, `form_field/1`); set `theme:`"
  }

  @doc """
  The validated configuration for `otp_app`. Raises `NimbleOptions.ValidationError` on
  invalid or unknown keys.
  """
  @spec fetch!(atom()) :: keyword()
  def fetch!(otp_app \\ :alkemist) do
    key = {__MODULE__, otp_app}

    case :persistent_term.get(key, nil) do
      nil ->
        config = validate!(otp_app)
        :persistent_term.put(key, config)
        config

      config ->
        config
    end
  end

  @doc "Validates the configuration of `otp_app` without caching it. Returns the validated keyword list."
  @spec validate!(atom()) :: keyword()
  def validate!(otp_app \\ :alkemist) do
    raw = Application.compile_env(otp_app, Alkemist, [])

    for {key, why} <- @removed, Keyword.has_key?(raw, key) do
      raise ArgumentError,
            "config :#{otp_app}, Alkemist, #{key}: was removed in Alkemist 3.0: #{why}. See guides/upgrading_to_3_0.md."
    end

    NimbleOptions.validate!(raw, Schema.schema())
  end

  @doc "Drops the cached configuration of `otp_app` (or of every app), e.g. after changing it in tests."
  @spec reset(atom() | :all) :: :ok
  def reset(otp_app \\ :all)

  def reset(:all) do
    for {{__MODULE__, _} = key, _} <- :persistent_term.get(), do: :persistent_term.erase(key)
    :ok
  end

  def reset(otp_app) do
    :persistent_term.erase({__MODULE__, otp_app})
    :ok
  end

  @doc "Returns one configuration value."
  @spec get(atom(), atom()) :: term()
  def get(key, otp_app \\ :alkemist), do: Keyword.get(fetch!(otp_app), key)

  @doc "The Ecto repo."
  def repo(otp_app \\ :alkemist), do: get(:repo, otp_app)

  @doc "The authorization provider module, see `Alkemist.Authorization`."
  def authorization_provider(otp_app \\ :alkemist), do: get(:authorization_provider, otp_app)

  @doc "Where denied requests are sent: a path, `{module, fun}` or `:render`."
  def forbidden_redirect_to(otp_app \\ :alkemist), do: get(:forbidden_redirect_to, otp_app)

  @doc "Pagination settings."
  def pagination(otp_app \\ :alkemist), do: get(:pagination, otp_app)

  @doc "CSV export settings."
  def csv(otp_app \\ :alkemist), do: get(:csv, otp_app)

  @doc "The search provider module."
  def search_provider(otp_app \\ :alkemist), do: get(:query, otp_app)[:search]

  @doc "The pagination provider module."
  def pagination_provider(otp_app \\ :alkemist), do: get(:query, otp_app)[:paginate]
end
