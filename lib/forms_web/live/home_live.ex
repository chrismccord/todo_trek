defmodule FormsWeb.HomeLive do
  use FormsWeb, :live_view

  alias Forms.Todos
  alias Forms.Todos.Todo

  def render(assigns) do
    ~H"""
    <div id="lists" phx-update="stream" class="space-y-5">
      <div :for={{id, list} <- @streams.lists} id={id}>
        <.header>
          <%= list.title %>
          <:actions>
            <.link patch={~p"/lists/new"}>
              <.button>New List</.button>
            </.link>
          </:actions>
        </.header>

        <.button phx-click={JS.push("new", value: %{at: 0, list_id: list.id})}>prepend</.button>
        <div id={"todos-#{list.id}"} class="space-y-3 my-5" phx-update="stream">
          <div :for={{id, todo} <- @streams["todos-#{list.id}"]} id={id}>
            <.simple_form
              for={todo}
              phx-change="validate"
              phx-submit="save"
              phx-value-id={todo.data.id}
              phx-value-list_id={list.id}
            >
              <div class="flex">
                <button type="button" phx-click="delete" phx-value-id={todo.data.id} class="w-10">
                  <.icon name="hero-x-mark" />
                </button>
                <div class="flex-auto">
                  <.input
                    type="text"
                    field={todo[:title]}
                    placeholder="New todo..."
                    phx-mounted={JS.focus()}
                  />
                </div>
              </div>
            </.simple_form>
          </div>
        </div>
        <.button phx-click={JS.push("new", value: %{at: -1, list_id: list.id})}>append</.button>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    lists = Todos.list_lists(socket.assigns.scope, 10)

    socket =
      Enum.reduce(lists, socket, fn list, acc ->
        stream(acc, "todos-#{list.id}", for(todo <- list.todos, do: to_change_form(todo, %{})))
      end)

    {:ok, stream(socket, :lists, lists)}
  end

  def handle_event("validate", %{"todo" => todo_params, "list_id" => list_id} = params, socket) do
    list = Todos.get_list!(list_id)
    todo = %Todo{id: params["id"], list_id: list.id}

    {:noreply,
     socket
     |> stream_insert(:lists, list)
     |> stream_insert_todo(list.id, to_change_form(todo, todo_params, :validate))}
  end

  def handle_event("save", %{"id" => id, "todo" => params}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(socket.assigns.scope, todo, params) do
      {:ok, updated_todo} ->
        {:noreply,
         socket
         |> stream_insert(:lists, todo.list)
         |> stream_insert_todo(todo.list.id, to_change_form(updated_todo, %{}))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> stream_insert(:lists, todo.list)
         |> stream_insert_todo(todo.list.id, to_change_form(changeset, %{}))}
    end
  end

  def handle_event("save", %{"todo" => params, "list_id" => list_id}, socket) do
    list = Todos.get_list!(list_id)
    {:ok, new_todo} = Todos.create_todo(socket.assigns.scope, list, params)
    empty_todo = to_change_form(build_todo(list_id), %{})

    {:noreply,
     socket
     |> stream_insert(:lists, list)
     |> stream_insert_todo(list.id, to_change_form(new_todo, %{}))
     |> stream_delete_todo(list.id, empty_todo)
     |> stream_insert_todo(list.id, empty_todo)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(socket.assigns.scope, todo)

    {:noreply,
     socket
     |> stream_insert(:lists, todo.list)
     |> stream_delete_todo(todo.list.id, to_change_form(todo, %{}))}
  end

  def handle_event("new", %{"at" => at, "list_id" => list_id}, socket) do
    list = Todos.get_list!(list_id)
    todo = build_todo(list.id)

    {:noreply,
     socket
     |> stream_insert(:lists, list)
     |> stream_insert_todo(list.id, to_change_form(todo, %{}), at: at)}
  end

  defp to_change_form(todo_or_changeset, params, action \\ nil) do
    changeset =
      todo_or_changeset
      |> Todos.change_todo(params)
      |> Map.put(:action, action)

    to_form(changeset, as: "todo", id: "form-#{changeset.data.list_id}-#{changeset.data.id}")
  end

  defp build_todo(list_id), do: %Todo{list_id: list_id}

  defp stream_insert_todo(socket, list_id, todo_form, opts \\ []) do
    stream_insert(socket, "todos-#{list_id}", todo_form, opts)
  end

  defp stream_delete_todo(socket, list_id, todo_form) do
    stream_delete(socket, "todos-#{list_id}", todo_form)
  end
end
