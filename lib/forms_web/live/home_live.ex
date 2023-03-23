defmodule FormsWeb.HomeLive do
  use FormsWeb, :live_view

  alias Forms.Todos
  alias Forms.Todos.Todo

  def render(assigns) do
    ~H"""
    <.button phx-click={JS.push("new", value: %{at: 0})}>prepend</.button>
    <div id="todos" class="space-y-3 my-5" phx-update="stream">
      <div :for={{id, todo} <- @streams.todos} id={id}>
        <.simple_form for={todo} phx-change="validate" phx-submit="save" phx-value-id={todo[:id].value}>
          <div class="flex">
            <button type="button" phx-click="delete" phx-value-id={todo[:id].value} class="w-10">
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
    <.button phx-click={JS.push("new", value: %{at: -1})}>append</.button>
    """
  end

  def mount(_params, _session, socket) do
    todos = for todo <- Todos.list_todos(100) ++ [build_todo()], do: to_change_form(todo, %{})
    {:ok, stream(socket, :todos, todos)}
  end

  def handle_event("validate", %{"todo" => %{"id" => id} = params}, socket) do
    {:noreply, stream_insert(socket, :todos, to_change_form(%Todo{id: id}, params, :validate))}
  end

  def handle_event("save", %{"todo" => %{"id" => id} = params}, socket) do
    case Todos.get_todo(id) do
      %Todo{} = todo ->
        case Todos.update_todo(todo, params) do
          {:ok, updated_todo} ->
            {:noreply, stream_insert(socket, :todos, to_change_form(updated_todo, %{}))}

          {:error, changeset} ->
            {:noreply, stream_insert(socket, :todos, to_change_form(changeset, %{}))}
        end

      nil ->
        {:ok, new_todo} = Todos.create_todo(params)

        {:noreply,
         socket
         |> stream_insert(:todos, to_change_form(new_todo, %{}))
         |> stream_insert(:todos, to_change_form(build_todo(), %{}))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Todos.delete_todo(id)
    {:noreply, stream_delete(socket, :todos, to_change_form(%Todo{id: id}, %{}))}
  end

  def handle_event("new", %{"at" => at}, socket) do
    {:noreply, stream_insert(socket, :todos, to_change_form(build_todo(), %{}), at: at)}
  end

  defp to_change_form(todo_or_changeset, params, action \\ nil) do
    changeset =
      todo_or_changeset
      |> Todos.change_todo(params)
      |> Map.put(:action, action)

    to_form(changeset, as: "todo", id: "form-#{changeset.data.id}")
  end

  defp build_todo, do: %Todo{id: Ecto.UUID.generate()}
end
