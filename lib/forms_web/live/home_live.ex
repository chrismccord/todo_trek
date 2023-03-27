defmodule FormsWeb.TodoListComponent do
  use FormsWeb, :live_component

  alias Forms.{Events, Todos}
  alias Forms.Todos.Todo

  def render(assigns) do
    ~H"""
    <div>
      <div
        id={"todos-#{@list_id}"}
        phx-update="stream"
        phx-hook="Sortable"
        data-drop="reposition"
        class="grid grid-cols-1 gap-2"
      >
        <div
          :for={{id, form} <- @streams.todos}
          id={id}
          data-id={form.data.id}
          class="relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-2 shadow-sm focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400"
        >
          <.simple_form
            for={form}
            phx-change="validate"
            phx-submit="save"
            phx-value-id={form.data.id}
            phx-target={@myself}
            class="min-w-0 flex-1"
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
                    if(form.data.status == :completed, do: "bg-green-600", else: "bg-gray-300")
                  ]}
                />
              </button>
              <div class="flex-auto">
                <.input
                  type="text"
                  field={form[:title]}
                  border={false}
                  strike_through={form.data.status == :completed}
                  placeholder="New todo..."
                  phx-mounted={JS.focus()}
                  phx-keydown={!form.data.id && JS.push("discard", target: @myself)}
                  phx-key="escape"
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
    {:ok,
     socket
     |> assign(list_id: list.id, scope: assigns.scope)
     |> maybe_stream(list)}
  end

  defp maybe_stream(socket, %Todos.List{} = list) do
    if socket.assigns[:streams][:todos] do
      socket
    else
      todo_forms = Enum.map(list.todos, &to_change_form(&1, %{}))
      stream(socket, :todos, todo_forms)
    end
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

  def handle_event("reposition", %{"id" => id, "new" => new_idx, "old" => _old_idx}, socket) do
    todo = Todos.get_todo!(socket.assigns.scope, id)
    Todos.update_todo_position(socket.assigns.scope, todo, new_idx)
    {:noreply, socket}
  end

  def handle_event("discard", _params, socket) do
    todo = build_todo(socket.assigns.list_id)
    {:noreply, stream_delete(socket, :todos, to_change_form(todo, %{}))}
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

defmodule FormsWeb.HomeLive do
  use FormsWeb, :live_view

  alias Forms.{Events, Todos}

  def render(assigns) do
    ~H"""
    <div id="lists" phx-update="stream" class="grid sm:grid-cols-1 md:grid-cols-3 gap-2">
      <div :for={{id, list} <- @streams.lists} id={id} class="bg-gray-100 py-4 rounded-lg">
        <div class="mx-auto max-w-7xl px-4 space-y-4">
          <.header>
            <%= list.title %>
            <:actions>
              <.link patch={~p"/lists/#{list}/edit"}>
                <.icon name="hero-pencil-square" alt="Edit list"/>
              </.link>
            </:actions>
          </.header>
          <.live_component
            id={list.id}
            module={FormsWeb.TodoListComponent}
            scope={@scope}
            list={list}
          />
        </div>
      </div>
    </div>
    <.modal :if={@live_action in [:edit_list]} id="list-modal" show on_cancel={JS.patch(~p"/")}>
      <.live_component
        scope={@scope}
        module={FormsWeb.ListLive.FormComponent}
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

    lists = Todos.active_lists(socket.assigns.scope, 10)
    {:ok, stream(socket, :lists, lists)}
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

  def handle_info({Forms.Todos, %Events.ListAdded{list: list}}, socket) do
    {:noreply, stream_insert(socket, :lists, list)}
  end

  def handle_info({Forms.Todos, %Events.ListUpdated{list: list}}, socket) do
    {:noreply, stream_insert(socket, :lists, list)}
  end

  def handle_info({Forms.Todos, %_event{todo: todo} = event}, socket) do
    send_update(FormsWeb.TodoListComponent, id: todo.list_id, event: event)
    {:noreply, socket}
  end
end
