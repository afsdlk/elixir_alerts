defmodule AlertsWeb.Helpers do
  import Phoenix.HTML
  # import Phoenix.HTML.Form
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag

  @locales Application.get_env(:jumbo, :locales)

  def locales(), do: @locales

  def debug() do
    Application.get_env(:jumbo, __MODULE__)[:debug]
  end

  def error_boundary(fun) when is_function(fun, 0), do: error_boundary(:div, fun)

  def error_boundary(tag, fun) when is_function(fun, 0) do
    if Application.get_env(:jumbo, Xavier.Endpoint)[:debug_errors] do
      # let it crash => will show phoenix error debugger
      fun.()
    else
      try do
        fun.()
      rescue
        _ ->
          # TODO log and track error
          Phoenix.HTML.Tag.content_tag(tag, "failed to render", class: "render-error")
      end
    end
  end

  def text_error_class(condition), do: text_error_class(condition, :text)

  def text_error_class(false, _), do: ""
  def text_error_class(true, :bg), do: "bg-danger"
  def text_error_class(true, :text), do: "text-danger font-bold"

  def format_date_local_millis(nil), do: ""
  def format_date_local_millis(""), do: ""

  def format_date_local_millis(ts) when is_binary(ts) do
    ts
    |> Timex.parse!("{ISO:Extended}")
    |> format_date_local_millis()
  end

  def format_date_local_millis(ts) do
    ts
    |> Timex.Timezone.convert("Europe/Zurich")
    |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}{ss}")
  end

  def format_date_local(nil), do: ""
  def format_date_local(""), do: ""

  def format_date_local(ts) when is_binary(ts) do
    ts
    |> Timex.parse!("{ISO:Extended}")
    |> format_date_local()
  end

  def format_date_local(ts) do
    ts
    |> Timex.Timezone.convert("Europe/Zurich")
    |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}")
  end

  def format_date_relative(nil), do: ""
  def format_date_relative(""), do: ""

  def format_date_relative(ts) when is_binary(ts) do
    ts
    |> Timex.parse!("{ISO:Extended}")
    |> format_date_relative()
  end

  def format_date_relative(ts) do
    ts
    |> Timex.format!("{relative}", :relative)
  end

  def format_date_relative_and_local(nil), do: ""
  def format_date_relative_and_local(""), do: ""

  def format_date_relative_and_local(ts) when is_binary(ts) do
    ts
    |> Timex.parse!("{ISO:Extended}")
    |> format_date_relative_and_local()
  end

  def format_date_relative_and_local(ts) do
    "#{format_date_relative(ts)} (#{format_date_local(ts)})"
  end

  def format_duration(nil), do: ""

  def format_duration(%Timex.Duration{} = duration) do
    duration |> Timex.format_duration(:humanized)
  end

  def is_before?(nil, _), do: false
  def is_before?(_, nil), do: false
  def is_before?(d1, d2), do: Timex.before?(d1, d2)

  def pagination_text(list) do
    ~e"""
    Displaying <%= list.first %> to <%= list.last %> of <%= list.count %> results
    """
  end

  def pagination_links(_conn, list, route) do
    content_tag :div, class: "pagination" do
      previous =
        case list.has_prev do
          true ->
            link(
              "Previous page",
              to: route <> Integer.to_string(list.prev_page),
              class: "btn-primary btn-sm active"
            )

          false ->
            content_tag(:span, "Previous page", class: "btn-basic btn-sm disabled")
        end

      next =
        case list.has_next do
          true ->
            link(
              "Next page",
              to: route <> Integer.to_string(list.next_page),
              class: "btn-primary btn-sm active"
            )

          false ->
            content_tag(:span, "Next page", class: "btn-basic btn-sm disabled")
        end

      if list.has_next or list.has_prev do
        [previous, " ", next]
      else
        []
      end
    end
  end

  def active_tab_class(current, active) do
    if current == active do
      "active"
    else
      ""
    end
  end
end
