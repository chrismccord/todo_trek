defmodule TodoTrekWeb.HomeLive do
  use TodoTrekWeb, :live_view

  alias TodoTrek.{Events, Todos, ActivityLog}
  alias TodoTrekWeb.Timeline

  def render(assigns) do
    ~H"""
    <div id="home" class="space-y-5">
      <.header>
        Your Lists
        <:actions>
          <.link patch={~p"/lists/new"}>
            <.button>New List</.button>
          </.link>
        </:actions>
      </.header>
      <div
        id="lists"
        phx-update="stream"
        phx-hook="Sortable"
        class="grid sm:grid-cols-1 md:grid-cols-3 gap-2"
      >
        <div
          :for={{id, list} <- @streams.lists}
          id={id}
          data-id={list.id}
          class="bg-gray-100 py-4 rounded-lg"
        >
          <div class="mx-auto max-w-7xl px-4 space-y-4">
            <.header>
              <%= list.title %>
              <:actions>
                <.link patch={~p"/lists/#{list}/edit"} alt="Edit list">
                  <.icon name="hero-pencil-square" />
                </.link>
                <.link phx-click="delete-list" phx-value-id={list.id} alt="delete list" data-confirm="Are you sure?">
                  <.icon name="hero-x-mark" />
                </.link>
              </:actions>
            </.header>
            <.live_component
              id={list.id}
              module={TodoTrekWeb.TodoListComponent}
              scope={@scope}
              list={list}
            />
          </div>
        </div>
      </div>
      <Timeline.activity_logs stream={@streams.activity_logs} page={@page} end_of_timeline?={@end_of_timeline?}/>
    </div>
    <.modal
      :if={@live_action in [:new_list, :edit_list]}
      id="list-modal"
      show
      on_cancel={JS.patch(~p"/")}
    >
      <.live_component
        scope={@scope}
        module={TodoTrekWeb.ListLive.FormComponent}
        id={@list.id || :new}
        title={@page_title}
        action={@live_action}
        list={@list}
        patch={~p"/"}
      />
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Todos.subscribe(socket.assigns.scope)
    end

    lists = Todos.active_lists(socket.assigns.scope, 20)

    {:ok,
     socket
     |> assign(page: 1, per_page: 20)
     |> stream(:lists, lists)
     |> paginate_logs(1)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :dashboard, _params) do
    socket
    |> assign(:page_title, "Dashboard")
    |> assign(:list, nil)
  end

  defp apply_action(socket, :new_list, _params) do
    socket
    |> assign(:page_title, "New List")
    |> assign(:list, %Todos.List{})
  end

  defp apply_action(socket, :edit_list, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit List")
    |> assign(:list, Todos.get_list!(socket.assigns.scope, id))
  end

  def handle_info({TodoTrek.Todos, %Events.ListAdded{list: list} = event}, socket) do
    {:noreply,
     socket
     |> stream_insert(:lists, list)
     |> stream_new_log(event)}
  end

  def handle_info({TodoTrek.Todos, %Events.ListUpdated{list: list} = event}, socket) do
    {:noreply,
     socket
     |> stream_insert(:lists, list)
     |> stream_new_log(event)}
  end

  def handle_info({TodoTrek.Todos, %Events.ListDeleted{list: list} = event}, socket) do
    {:noreply,
     socket
     |> stream_delete(:lists, list)
     |> stream_new_log(event)}
  end

  def handle_info({TodoTrek.Todos, %_event{todo: todo} = event}, socket) do
    send_update(TodoTrekWeb.TodoListComponent, id: todo.list_id, event: event)
    {:noreply, stream_new_log(socket, event)}
  end

  def handle_info({TodoTrek.Todos, %Events.ListRepositioned{list: list} = event}, socket) do
    {:noreply,
     socket
     |> stream_insert(:lists, list, at: list.position)
     |> stream_new_log(event)}
  end

  def handle_event("reposition", %{"id" => id, "new" => new_idx, "old" => _old_idx}, socket) do
    list = Todos.get_list!(socket.assigns.scope, id)
    Todos.update_list_position(socket.assigns.scope, list, new_idx)
    {:noreply, socket}
  end

  def handle_event("delete-list", %{"id" => id}, socket) do
    list = Todos.get_list!(socket.assigns.scope, id)
    Todos.delete_list(socket.assigns.scope, list)
    {:noreply, socket}
  end

  def handle_event("top", _, socket) do
    {:noreply, socket |> put_flash(:info, "You reached the top") |> paginate_logs(1)}
  end

  def handle_event("next-page", _, socket) do
    {:noreply, paginate_logs(socket, socket.assigns.page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_logs(socket, 1)}
  end

  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_logs(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp stream_new_log(socket, %_{log: %ActivityLog.Entry{} = log} = _event) do
    stream_insert(socket, :activity_logs, log, at: 0)
  end

  defp stream_new_log(socket, %_{} = _event) do
    socket
  end

  defp paginate_logs(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, page: cur_page, scope: scope} = socket.assigns
    logs = ActivityLog.list_user_logs(scope, offset: (new_page - 1) * per_page, limit: per_page)

    {logs, at, limit} =
      if new_page >= cur_page do
        {logs, -1, per_page * 3 * -1}
      else
        {Enum.reverse(logs), 0, per_page * 3}
      end

    case logs do
      [] ->
        socket
        |> assign(end_of_timeline?: at == -1)
        |> stream(:activity_logs, [])

      [_ | _] = logs ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(page: new_page)
        |> stream(:activity_logs, logs, at: at, limit: limit)
    end
  end
end
