defmodule FormsWeb.ListLive.Index do
  use FormsWeb, :live_view

  alias Forms.Todos
  alias Forms.Todos.List

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :lists, Todos.active_lists(socket.assigns.scope, 100))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit List")
    |> assign(:list, Todos.get_list!(socket.assigns.scope, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New List")
    |> assign(:list, %List{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Lists")
    |> assign(:list, nil)
  end

  @impl true
  def handle_info({FormsWeb.ListLive.FormComponent, {:saved, list}}, socket) do
    {:noreply, stream_insert(socket, :lists, list)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    list = Todos.get_list!(socket.assigns.scope, id)
    {:ok, _} = Todos.delete_list(socket.assigns.scope, list)

    {:noreply, stream_delete(socket, :lists, list)}
  end
end
