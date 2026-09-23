defmodule Alkemist.Components.Value do
  @moduledoc """
  Safe rendering of a cell value. Strings are **escaped**; only `{:safe, _}` and rendered
  HEEx pass through, so HTML stored in the database never executes in the admin. Hosts
  change the rendering per column with `format: fn value, row -> ... end` or globally by
  overriding `value/1` in their `Alkemist.Theme`.
  """
  use Phoenix.Component
  import Alkemist.Components.Icons

  @doc "Renders a value according to its type."
  attr :value, :any, required: true
  attr :column, :map, default: %{}
  attr :row, :any, default: nil

  def value(%{column: %{format: format}} = assigns) when is_function(format, 2) do
    assigns
    |> assign(:value, format.(assigns.value, assigns.row))
    |> assign(:column, Map.delete(assigns.column, :format))
    |> value()
  end

  def value(%{value: {:safe, _}} = assigns), do: ~H"{@value}"
  def value(%{value: %Phoenix.LiveView.Rendered{}} = assigns), do: ~H"{@value}"
  def value(%{value: nil} = assigns), do: ~H|<span class="ak-faint">—</span>|

  def value(%{value: bool} = assigns) when is_boolean(bool) do
    ~H"""
    <.icon
      name={if @value, do: "hero-check-circle", else: "hero-x-circle"}
      class={["size-4", (@value && "text-ak-ok") || "text-ak-faint"]}
      aria-label={to_string(@value)}
    />
    """
  end

  def value(%{value: %Date{}} = assigns) do
    ~H|<time datetime={Date.to_iso8601(@value)}>{Date.to_iso8601(@value)}</time>|
  end

  def value(%{value: %NaiveDateTime{}} = assigns) do
    ~H|<time datetime={NaiveDateTime.to_iso8601(@value)}>{Calendar.strftime(@value, "%Y-%m-%d %H:%M")}</time>|
  end

  def value(%{value: %DateTime{}} = assigns) do
    ~H|<time datetime={DateTime.to_iso8601(@value)}>{Calendar.strftime(@value, "%Y-%m-%d %H:%M %Z")}</time>|
  end

  def value(%{value: %Time{}} = assigns), do: ~H|<time>{Calendar.strftime(@value, "%H:%M")}</time>|

  def value(%{value: %Decimal{}} = assigns),
    do: ~H|<span class="tabular-nums">{Decimal.to_string(@value, :normal)}</span>|

  def value(%{value: n} = assigns) when is_number(n), do: ~H|<span class="tabular-nums">{@value}</span>|

  def value(%{value: list} = assigns) when is_list(list) do
    ~H|{Enum.map_join(@value, ", ", &plain/1)}|
  end

  def value(%{value: %{__struct__: _} = struct} = assigns) do
    if String.Chars.impl_for(struct) do
      ~H"{to_string(@value)}"
    else
      ~H|<span class="ak-muted">{inspect(@value.__struct__)}</span>|
    end
  end

  def value(%{value: map} = assigns) when is_map(map), do: ~H|<code class="ak-code">{Jason.encode!(@value)}</code>|
  def value(assigns), do: ~H"{@value}"

  defp plain(%{__struct__: _} = s), do: if(String.Chars.impl_for(s), do: to_string(s), else: inspect(s))
  defp plain(v), do: to_string(v)
end
