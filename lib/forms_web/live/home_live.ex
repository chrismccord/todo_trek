defmodule FormsWeb.HomeLive do
  use FormsWeb, :live_view

  def render(assigns) do
    ~H"""
    <%= inspect(assigns) %>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, test: true)}
  end
end
