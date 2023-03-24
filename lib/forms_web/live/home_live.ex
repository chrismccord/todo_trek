defmodule FormsWeb.TodoListComponent do
  use FormsWeb, :live_component

  alias Forms.Todos
  alias Forms.Todos.Todo

  def render(assigns) do
    ~H"""
    <div>
      <div
        id={"todos-#{@list_id}"}
        phx-update="stream"
        phx-hook="Sortable"
        data-drop="reposition"
        class="space-y-3 my-5"
      >
        <div :for={{id, form} <- @streams.todos} id={id} data-id={form.data.id}>
          <.simple_form
            for={form}
            phx-change="validate"
            phx-submit="save"
            phx-value-id={form.data.id}
            phx-target={@myself}
          >
            <div class="flex">
              <button
                type="button"
                phx-click={JS.push("delete", target: @myself, value: %{id: form.data.id})}
                class="w-10"
              >
                <.icon name="hero-x-mark" />
              </button>
              <div class="flex-auto">
                <.input
                  type="text"
                  field={form[:title]}
                  placeholder="New todo..."
                  phx-mounted={JS.focus()}
                />
              </div>
            </div>
          </.simple_form>
        </div>
      </div>
      <.button phx-click={JS.push("new", value: %{at: -1, list_id: @list_id}, target: @myself)}>
        add todo
      </.button>
    </div>
    """
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

    {:noreply, stream_delete(socket, :todos, to_change_form(todo, %{}))}
  end

  def handle_event("new", %{"at" => at}, socket) do
    todo = build_todo(socket.assigns.list_id)

    {:noreply, stream_insert(socket, :todos, to_change_form(todo, %{}), at: at)}
  end

  def handle_event("reposition", %{"id" => id, "new" => new_idx, "old" => _old_idx}, socket) do
    todo = Todos.get_todo!(socket.assigns.scope, id)
    Todos.update_todo_position(socket.assigns.scope, todo, new_idx)
    {:noreply, stream_insert(socket, :todos, to_change_form(todo, %{}), at: new_idx)}
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

  alias Forms.Todos

  def render(assigns) do
    ~H"""
    <div id="lists" phx-update="stream" class="space-y-5">
      <div :for={{id, list} <- @streams.lists} id={id}>
        <.header>
          <%= list.title %>
          <:actions>
            <.link patch={~p"/lists/new"}>
              <.button>Edit List</.button>
            </.link>
          </:actions>
        </.header>
        <.live_component id={list.id} module={FormsWeb.TodoListComponent} scope={@scope} list={list} />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    lists = Todos.active_lists(socket.assigns.scope, 10)
    {:ok, stream(socket, :lists, lists)}
  end
end
