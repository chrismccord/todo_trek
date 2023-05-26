defmodule TodoTrek.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias TodoTrek.{Repo, Scope, Events}

  alias TodoTrek.Todos.{List, Todo}
  alias TodoTrek.ActivityLog

  @max_todos 1000

  @doc """
  Subscribers the given scope to the todo pubsub.

  For logged in users, this will be a topic scoped only to the logged in user.
  If the system is extended to allow shared lists, the topic subscription could
  be derived for a particular organizatoin or team, particlar list, and so on.
  """
  def subscribe(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(TodoTrek.PubSub, topic(scope))
  end

  @doc """
  Reorders a list in the current users board.

  Broadcasts `%Events.ListRepositioned{}` on the scoped topic when successful.
  """
  def update_list_position(%Scope{} = scope, %List{} = list, new_index) do
    Ecto.Multi.new()
    |> multi_reposition(:new, list, list, new_index, user_id: scope.current_user.id)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        new_list = %List{list | position: new_index}

        log =
          ActivityLog.log(scope, list, %{
            action: "list_position_updated",
            subject_text: list.title,
            before_text: list.position,
            after_text: new_index
          })

        broadcast(scope, %Events.ListRepositioned{list: new_list, log: log})

        :ok

      {:error, _failed_op, failed_val, _changes_so_far} ->
        {:error, failed_val}
    end
  end

  @doc """
  Updates the position of a todo in the list it belongs to.

  Broadcasts %Events.TodoRepositioned{} on the scoped topic.
  """
  def update_todo_position(%Scope{} = scope, %Todo{} = todo, new_index) do
    Ecto.Multi.new()
    |> multi_reposition(:new, todo, {List, todo.list_id}, new_index, list_id: todo.list_id)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        new_todo = %Todo{todo | position: new_index}

        log =
          ActivityLog.log(scope, todo, %{
            action: "todo_position_updated",
            subject_text: todo.title,
            before_text: todo.position,
            after_text: new_index
          })

        broadcast(scope, %Events.TodoRepositioned{todo: new_todo, log: log})

        :ok

      {:error, _failed_op, failed_val, _changes_so_far} ->
        {:error, failed_val}
    end
  end

  def change_todo(todo_or_changeset, attrs \\ %{}) do
    Todo.changeset(todo_or_changeset, attrs)
  end

  @doc """
  Moves a todo from one list to another.

  Broadcasts %Events.TodoDeleted{} on the scoped topic for the old list.
  Broadcasts %Events.TodoRepositioned{} on the scoped topic for the new list.
  """
  def move_todo_to_list(%Scope{} = scope, %Todo{} = todo, %List{} = list, at_index) do
    Ecto.Multi.new()
    |> Repo.multi_transaction_lock(:old_list, {List, todo.list_id})
    |> Repo.multi_transaction_lock(:new_list, list)
    |> multi_update_all(:dec_positions, fn _ ->
      from(t in Todo,
        where: t.list_id == ^todo.list_id,
        where:
          t.position > subquery(from og in Todo, where: og.id == ^todo.id, select: og.position),
        update: [inc: [position: -1]]
      )
    end)
    |> Ecto.Multi.run(:pos_at_end, fn repo, _changes ->
      position = repo.one(from t in Todo, where: t.list_id == ^list.id, select: count(t.id))
      {:ok, position}
    end)
    |> multi_update_all(:move_to_list, fn %{pos_at_end: pos_at_end} ->
      from(t in Todo,
        where: t.id == ^todo.id,
        update: [set: [list_id: ^list.id, position: ^pos_at_end]]
      )
    end)
    |> multi_reposition(:new, todo, list, at_index, list_id: list.id)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        new_todo = %Todo{todo | list: list, list_id: list.id, position: at_index}

        log =
          ActivityLog.log(scope, new_todo, %{
            action: "todo_moved",
            subject_text: new_todo.title,
            before_text: todo.list.title,
            after_text: list.title
          })

        broadcast(scope, %Events.TodoDeleted{todo: todo})
        broadcast(scope, %Events.TodoRepositioned{todo: new_todo, log: log})

        :ok

      {:error, _failed_op, failed_val, _changes_so_far} ->
        {:error, failed_val}
    end
  end

  @doc """
  Deletes a todo for the current scope.

  Broadcasts %Events.TodoDeleted{} on the scoped topic when successful.
  """
  def delete_todo(%Scope{} = scope, %Todo{} = todo) do
    Ecto.Multi.new()
    |> Repo.multi_transaction_lock(:list, {List, todo.list_id})
    |> multi_decrement_positions(:dec_rest_in_list, todo, list_id: todo.list_id)
    |> Ecto.Multi.delete(:todo, todo)
    |> Repo.transaction()
    |> case do
      {:ok, %{todo: todo}} ->
        log =
          ActivityLog.log(scope, todo, %{
            action: "todo_deleted",
            subject_text: todo.title,
            after_text: todo.list.title
          })

        broadcast(scope, %Events.TodoDeleted{todo: todo, log: log})

        {:ok, todo}

      {:error, _failed_op, failed_val, _changes_so_far} ->
        {:error, failed_val}
    end
  end

  @doc """
  Lists todos for the current scope.
  """
  def list_todos(%Scope{} = scope, limit) do
    Repo.all(
      from(t in Todo,
        where: t.user_id == ^scope.current_user.id,
        limit: ^limit,
        order_by: [asc: :position]
      )
    )
  end

  @doc """
  Toggles a todo status for the current scope.

  Broadcasts %Events.TodoToggled{} on the scoped topic when successful.
  """
  def toggle_complete(%Scope{} = scope, %Todo{} = todo) do
    new_status =
      case todo.status do
        :completed -> :started
        :started -> :completed
      end

    query = from(t in Todo, where: t.id == ^todo.id and t.user_id == ^scope.current_user.id)
    {1, _} = Repo.update_all(query, set: [status: new_status])
    new_todo = %Todo{todo | status: new_status}

    log =
      ActivityLog.log(scope, new_todo, %{
        action: "todo_toggled",
        subject_text: todo.title,
        before_text: todo.status,
        after_text: new_status
      })

    broadcast(scope, %Events.TodoToggled{todo: new_todo, log: log})

    {:ok, new_todo}
  end

  def get_todo!(%Scope{} = scope, id) do
    from(t in Todo, where: t.id == ^id and t.user_id == ^scope.current_user.id)
    |> Repo.one!()
    |> Repo.preload(:list)
  end

  @doc """
  Updates a todo for the current scope.

  Broadcasts %Events.TodoUpdated{} on the scoped topic when successful.
  """
  def update_todo(%Scope{} = scope, %Todo{} = todo, params) do
    todo
    |> Todo.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, new_todo} ->
        log =
          if todo.title != new_todo.title do
            ActivityLog.log(scope, new_todo, %{
              action: "todo_updated",
              subject_text: todo.title,
              after_text: new_todo.title
            })
          end

        broadcast(scope, %Events.TodoUpdated{todo: new_todo, log: log})

        {:ok, new_todo}

      other ->
        other
    end
  end

  @doc """
  Creates a todo for the current scope.

  Broadcasts %Events.TodoAdded{} on the scoped topic when successful.
  """
  def create_todo(%Scope{} = scope, %List{} = list, params) do
    todo = %Todo{
      user_id: scope.current_user.id,
      status: :started,
      list_id: list.id
    }

    Ecto.Multi.new()
    |> Repo.multi_transaction_lock(:list, list)
    |> Ecto.Multi.run(:position, fn repo, _changes ->
      position = repo.one(from t in Todo, where: t.list_id == ^list.id, select: count(t.id))

      {:ok, position}
    end)
    |> Ecto.Multi.insert(:todo, fn %{position: position} ->
      Todo.changeset(%Todo{todo | position: position}, params)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{todo: todo}} ->
        log =
          ActivityLog.log(scope, todo, %{
            action: "todo_created",
            subject_text: todo.title,
            after_text: list.title
          })

        broadcast(scope, %Events.TodoAdded{todo: todo, log: log})

        {:ok, todo}

      {:error, :todo, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns the active lists for the current scope.
  """
  def active_lists(%Scope{} = scope, limit) do
    from(l in List,
      where: l.user_id == ^scope.current_user.id,
      limit: ^limit,
      order_by: [asc: :position]
    )
    |> Repo.all()
    |> Repo.preload(
      todos:
        from(t in Todo,
          where: t.user_id == ^scope.current_user.id,
          limit: @max_todos,
          order_by: [asc: t.position]
        )
    )
  end

  @doc """
  Gets a single list owned by the scoped user.

  Raises `Ecto.NoResultsError` if the List does not exist.
  """
  def get_list!(%Scope{} = scope, id) do
    from(l in List, where: l.user_id == ^scope.current_user.id, where: l.id == ^id)
    |> Repo.one!()
    |> preload()
  end

  defp preload(resource), do: Repo.preload(resource, [:todos])

  @doc """
  Creates a list for the current scope.

  Broadcasts `%Events.ListAdded{}` on the scoped topic when successful.
  """
  def create_list(%Scope{} = scope, attrs \\ %{}) do
    Ecto.Multi.new()
    |> Repo.multi_transaction_lock(:user, scope.current_user)
    |> Ecto.Multi.run(:position, fn repo, _changes ->
      position =
        repo.one(from l in List, where: l.user_id == ^scope.current_user.id, select: count(l.id))

      {:ok, position}
    end)
    |> Ecto.Multi.insert(:list, fn %{position: position} ->
      List.changeset(%List{user_id: scope.current_user.id, position: position}, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{list: list}} ->
        list = Repo.preload(list, :todos)

        log =
          ActivityLog.log(scope, list, %{
            action: "list_created",
            subject_text: list.title
          })

        broadcast(scope, %Events.ListAdded{list: list, log: log})

        {:ok, list}

      {:error, _failed_op, failed_val, _changes_so_far} ->
        {:error, failed_val}
    end
  end

  @doc """
  Updates a list.

  Broadcasts %Events.ListUpdated{} on the scoped topic when successful.
  """
  def update_list(%Scope{} = scope, %List{} = list, attrs) do
    list
    |> List.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, new_list} ->
        log =
          if list.title != new_list.title do
            ActivityLog.log(scope, new_list, %{
              action: "list_updated",
              subject_text: list.title,
              after_text: new_list.title
            })
          end

        broadcast(scope, %Events.ListUpdated{list: new_list, log: log})

        {:ok, new_list}

      other ->
        other
    end
  end

  @doc """
  Deletes a list.

  Broadcasts %Events.ListDeleted{} on the scoped topic when successful.
  """
  def delete_list(%Scope{} = scope, %List{} = list) do
    Ecto.Multi.new()
    |> Repo.multi_transaction_lock(:user, scope.current_user)
    |> multi_decrement_positions(:dec_rest_in_parent, list, user_id: list.user_id)
    |> Ecto.Multi.delete(:list, list)
    |> Repo.transaction()
    |> case do
      {:ok, %{list: list}} ->
        log =
          ActivityLog.log(scope, list, %{
            action: "list_deleted",
            subject_text: list.title
          })

        broadcast(scope, %Events.ListDeleted{list: list, log: log})

        {:ok, list}

      {:error, _failed_op, failed_val, _changes_so_far} ->
        {:error, failed_val}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking list changes.

  ## Examples

      iex> change_list(list)
      %Ecto.Changeset{data: %List{}}

  """
  def change_list(%List{} = list, attrs \\ %{}) do
    List.changeset(list, attrs)
  end

  defp multi_update_all(multi, name, func, opts \\ []) do
    Ecto.Multi.update_all(multi, name, func, opts)
  end

  defp broadcast(%Scope{} = scope, event) do
    Phoenix.PubSub.broadcast(TodoTrek.PubSub, topic(scope), {__MODULE__, event})
  end

  defp topic(%Scope{} = scope), do: "todos:#{scope.current_user.id}"

  defp multi_reposition(%Ecto.Multi{} = multi, name, %type{} = struct, lock, new_idx, where_query)
      when is_integer(new_idx) do
    old_position = from(og in type, where: og.id == ^struct.id, select: og.position)

    multi
    |> Repo.multi_transaction_lock(name, lock)
    |> Ecto.Multi.run({:index, name}, fn repo, _changes ->
      case repo.one(from(t in type, where: ^where_query, select: count(t.id))) do
        count when new_idx < count -> {:ok, new_idx}
        count -> {:ok, count - 1}
      end
    end)
    |> multi_update_all({:dec_positions, name}, fn %{{:index, ^name} => computed_index} ->
      from(t in type,
        where: ^where_query,
        where: t.id != ^struct.id,
        where: t.position > subquery(old_position) and t.position <= ^computed_index,
        update: [inc: [position: -1]]
      )
    end)
    |> multi_update_all({:inc_positions, name}, fn %{{:index, ^name} => computed_index} ->
      from(t in type,
        where: ^where_query,
        where: t.id != ^struct.id,
        where: t.position < subquery(old_position) and t.position >= ^computed_index,
        update: [inc: [position: 1]]
      )
    end)
    |> multi_update_all({:position, name}, fn %{{:index, ^name} => computed_index} ->
      from(t in type,
        where: t.id == ^struct.id,
        update: [set: [position: ^computed_index]]
      )
    end)
  end

  defp multi_decrement_positions(%Ecto.Multi{} = multi, name, %type{} = struct, where_query) do
    multi_update_all(multi, name, fn _ ->
      from(t in type,
        where: ^where_query,
        where:
          t.position > subquery(from og in type, where: og.id == ^struct.id, select: og.position),
        update: [inc: [position: -1]]
      )
    end)
  end

  def test(to, %Scope{} = scope) do
    parent = self()
    Node.spawn_link(to, fn ->
      IO.inspect(scope)
      send(parent, {:done, node()})
    end)
  end
end
