defmodule TodoTrekWeb.TodoListComponent do
  use TodoTrekWeb, :live_component

  alias TodoTrek.{Events, Todos}
  alias TodoTrek.Todos.Todo

  def render(assigns) do
    ~H"""
    <div>
      <div
        id={"todos-#{@list_id}"}
        phx-update="stream"
        phx-hook="Sortable"
        class="grid grid-cols-1 gap-2"
        data-group="todos"
        data-list_id={@list_id}
      >
        <div
          :for={{id, form} <- @streams.todos}
          id={id}
          data-id={form.data.id}
          data-list_id={form.data.list_id}
          class="
          relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-2 shadow-sm
          focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400
          drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0
          drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0
          "
        >
          <.simple_form
            for={form}
            phx-change="validate"
            phx-submit="save"
            phx-value-id={form.data.id}
            phx-target={@myself}
            class="min-w-0 flex-1 drag-ghost:opacity-0"
          >
            <div class="flex">
              <button
                :if={form.data.id}
                type="button"
                phx-click={JS.push("toggle_complete", target: @myself, value: %{id: form.data.id})}
                class="w-10"
              >
                <.icon
                  name="hero-check-circle"
                  class={[
                    "w-7 h-7",
                    if(form[:status].value == :completed, do: "bg-green-600", else: "bg-gray-300")
                  ]}
                />
              </button>
              <div class="flex-auto">
                <input type="hidden" name={form[:status].name} value={form[:status].value} />
                <.input
                  type="text"
                  field={form[:title]}
                  border={false}
                  strike_through={form[:status].value == :completed}
                  placeholder="New todo..."
                  phx-mounted={!form.data.id && JS.focus()}
                  phx-keydown={!form.data.id && JS.push("discard", target: @myself)}
                  phx-key="escape"
                  phx-blur={form.data.id && JS.dispatch("submit", to: "##{form.id}")}
                  phx-target={@myself}
                />
              </div>
              <button
                :if={form.data.id}
                type="button"
                phx-click={
                  JS.push("delete", target: @myself, value: %{id: form.data.id}) |> hide("##{id}")
                }
                class="w-10 -mt-1"
              >
                <.icon name="hero-x-mark" />
              </button>
            </div>
          </.simple_form>
        </div>
      </div>
      <.button
        phx-click={JS.push("new", value: %{at: -1, list_id: @list_id}, target: @myself)}
        class="mt-4"
      >
        add todo
      </.button>
      <.button phx-click={JS.push("reset", target: @myself)} class="mt-4">reset</.button>
    </div>
    """
  end

  def update(%{event: %Events.TodoToggled{todo: todo}}, socket) do
    {:ok, stream_insert(socket, :todos, to_change_form(todo, %{}))}
  end

  def update(%{event: %Events.TodoAdded{todo: todo}}, socket) do
    {:ok, stream_insert(socket, :todos, to_change_form(todo, %{}))}
  end

  def update(%{event: %Events.TodoUpdated{todo: todo}}, socket) do
    {:ok, stream_insert(socket, :todos, to_change_form(todo, %{}))}
  end

  def update(%{event: %Events.TodoRepositioned{todo: todo}}, socket) do
    {:ok, stream_insert(socket, :todos, to_change_form(todo, %{}), at: todo.position)}
  end

  def update(%{event: %Events.TodoDeleted{todo: todo}}, socket) do
    {:ok, stream_delete(socket, :todos, to_change_form(todo, %{}))}
  end

  def update(%{list: list} = assigns, socket) do
    todo_forms = Enum.map(list.todos, &to_change_form(&1, %{}))

    {:ok,
     socket
     |> assign(list_id: list.id, scope: assigns.scope)
     |> stream(:todos, todo_forms)}
  end

  def handle_event("validate", %{"todo" => todo_params} = params, socket) do
    todo = %Todo{id: params["id"], list_id: socket.assigns.list_id}

    {:noreply, stream_insert(socket, :todos, to_change_form(todo, todo_params, :validate))}
  end

  def handle_event("save", %{"id" => id, "todo" => params}, socket) do
    todo = Todos.get_todo!(socket.assigns.scope, id)

    case Todos.update_todo(socket.assigns.scope, todo, params) do
      {:ok, updated_todo} ->
        {:noreply, stream_insert(socket, :todos, to_change_form(updated_todo, %{}))}

      {:error, changeset} ->
        {:noreply, stream_insert(socket, :todos, to_change_form(changeset, %{}, :insert))}
    end
  end

  def handle_event("save", %{"todo" => params}, socket) do
    list = Todos.get_list!(socket.assigns.scope, socket.assigns.list_id)

    case Todos.create_todo(socket.assigns.scope, list, params) do
      {:ok, new_todo} ->
        empty_form = to_change_form(build_todo(socket.assigns.list_id), %{})

        {:noreply,
         socket
         |> stream_insert(:todos, to_change_form(new_todo, %{}))
         |> stream_delete(:todos, empty_form)
         |> stream_insert(:todos, empty_form)}

      {:error, changeset} ->
        {:noreply, stream_insert(socket, :todos, to_change_form(changeset, params, :insert))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(socket.assigns.scope, id)
    {:ok, _} = Todos.delete_todo(socket.assigns.scope, todo)

    {:noreply, socket}
  end

  def handle_event("toggle_complete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(socket.assigns.scope, id)
    {:ok, _todo} = Todos.toggle_complete(socket.assigns.scope, todo)

    {:noreply, socket}
  end

  def handle_event("new", %{"at" => at}, socket) do
    todo = build_todo(socket.assigns.list_id)
    {:noreply, stream_insert(socket, :todos, to_change_form(todo, %{}), at: at)}
  end

  def handle_event("reset", _, socket) do
    todo = build_todo(socket.assigns.list_id)
    {:noreply, stream(socket, :todos, [to_change_form(todo, %{})], reset: true)}
  end

  def handle_event("reposition", %{"id" => id, "new" => new_idx, "old" => _} = params, socket) do
    case params do
      %{"list_id" => old_list_id, "to" => %{"list_id" => old_list_id}} ->
        todo = Todos.get_todo!(socket.assigns.scope, id)
        Todos.update_todo_position(socket.assigns.scope, todo, new_idx)
        {:noreply, socket}

      %{"list_id" => _old_list_id, "to" => %{"list_id" => new_list_id}} ->
        todo = Todos.get_todo!(socket.assigns.scope, id)
        list = Todos.get_list!(socket.assigns.scope, new_list_id)
        Todos.move_todo_to_list(socket.assigns.scope, todo, list, new_idx)
        {:noreply, socket}
    end
  end

  def handle_event("discard", _params, socket) do
    todo = build_todo(socket.assigns.list_id)
    {:noreply, stream_delete(socket, :todos, to_change_form(todo, %{}))}
  end

  def handle_event("restore_if_unsaved", %{"value" => val} = params, socket) do
    id = params["id"]
    todo = Todos.get_todo!(socket.assigns.scope, id)

    if todo.title == val do
      {:noreply, socket}
    else
      {:noreply, stream_insert(socket, :todos, to_change_form(todo, %{}))}
    end
  end

  defp to_change_form(todo_or_changeset, params, action \\ nil) do
    changeset =
      todo_or_changeset
      |> Todos.change_todo(params)
      |> Map.put(:action, action)

    to_form(changeset, as: "todo", id: "form-#{changeset.data.list_id}-#{changeset.data.id}")
  end

  defp build_todo(list_id), do: %Todo{list_id: list_id}
end

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
        assign(socket, end_of_timeline?: at == -1)

      [_ | _] = logs ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(page: if(logs == [], do: cur_page, else: new_page))
        |> stream(:activity_logs, logs, at: at, limit: limit)
    end
  end
end
