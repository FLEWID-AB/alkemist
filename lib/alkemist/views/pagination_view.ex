defmodule Alkemist.PaginationView do
  use Phoenix.HTML
  import Alkemist.ViewHelpers

  @max_page_links 5
  @per_page_values [10, 25, 50, 100]

  @doc """
  Creates Bootstrap 4 pagination links
  """
  def pagination_links(conn, pagination, resource, route_params) do
    if pagination.total_pages > 1 do
      content_tag(:ul, class: "pagination") do
        [first_link(conn, pagination, resource, route_params),
          previous_link(conn, pagination, resource, route_params)] ++
          middle_page_links(conn, pagination, resource, route_params) ++
          [next_link(conn, pagination, resource, route_params), last_link(conn, pagination, resource, route_params)]
      end
    end
  end

  defp first_link(conn, %{current_page: current_page}, resource, route_params) do
    if current_page == 1 do
      page_link("First", "#", "disabled")
    else
      params = get_link_params(conn, 1)
      page_link("First", resource_action_path(conn, resource, :index, route_params, params))
    end
  end

  defp last_link(conn, %{current_page: current_page, total_pages: total_pages}, resource, route_params) do
    if current_page == total_pages do
      page_link("Last", "#", "disabled")
    else
      params = get_link_params(conn, total_pages)
      page_link("Last", resource_action_path(conn, resource, :index, route_params, params))
    end
  end

  defp previous_link(conn, %{prev_page: prev_page}, resource, route_params) do
    if prev_page == nil do
      page_link("Previous", "#", "disabled")
    else
      params = get_link_params(conn, prev_page)
      page_link("Previous", resource_action_path(conn, resource, :index, route_params, params))
    end
  end

  defp next_link(conn, %{next_page: next_page}, resource, route_params) do
    if next_page == nil do
      page_link("Next", "#", "disabled")
    else
      params = get_link_params(conn, next_page)
      page_link("Next", resource_action_path(conn, resource, :index, route_params, params))
    end
  end

  defp middle_page_links(conn, %{total_pages: total_pages, current_page: current_page}, resource, route_params) do
    lower_limit =
      cond do
        current_page <= div(@max_page_links, 2) ->
          1

        current_page >= total_pages - div(@max_page_links, 2) ->
          Enum.max([0, total_pages - @max_page_links]) + 1

        true ->
          current_page - div(@max_page_links, 2)
      end

    upper_limit = lower_limit + @max_page_links - 1

    Enum.map(lower_limit..upper_limit, fn page ->
      cond do
        page == current_page ->
          page_link(page, "#", "active")

        page > total_pages ->
          ""

        true ->
          params = get_link_params(conn, page)
          path = resource_action_path(conn, resource, :index, route_params, params)
          page_link(page, path)
      end
    end)
  end

  def per_page_links(conn, %{per_page: per_page}, resource, route_params) do
    content_tag(:ul, class: "per-page-nav") do
      Enum.map(@per_page_values, fn val ->
        content_tag(:li, []) do
          if val == per_page do
            "#{val}"
          else
            params = get_per_page_params(conn, val)
            link("#{val}", to: resource_action_path(conn, resource, :index, route_params, params))
          end
        end
      end)
    end
  end

  defp page_link(page, path, additional_class \\ "") do
    class = "page-item #{additional_class}"

    content_tag(:li, class: class) do
      link("#{page}", to: path, class: "page-link")
    end
  end

  defp get_link_params(conn, page) do
    conn
    |> get_default_link_params()
    |> Map.put(:page, page)
  end

  defp get_per_page_params(conn, per_page) do
    conn
    |> get_default_link_params()
    |> Map.put(:per_page, per_page)
  end
end
