defmodule Forms.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias Forms.{Repo, Scope}

  alias Forms.Todos.{List, Todo}

  def change_position(%Scope{} = _scope, %Todo{} = todo, new_index) do
    old_index = todo.position

    multi =
      Ecto.Multi.new()
      |> lock_list(todo)
      |> Ecto.Multi.run(:index, fn repo, _changes ->
        case repo.one(from(t in Todo, select: count(t.id))) do
          count when new_index < count -> {:ok, new_index}
          count -> {:ok, count - 1}
        end
      end)
      |> multi_update_all(:dec_positions, fn %{index: new_index} ->
        from(t in Todo,
          where: t.list_id == ^todo.list_id and t.id != ^todo.id,
          where: t.position > ^old_index and t.position <= ^new_index,
          update: [inc: [position: -1]]
        )
      end)
      |> multi_update_all(:inc_positions, fn %{index: new_index} ->
        from(t in Todo,
          where: t.list_id == ^todo.list_id and t.id != ^todo.id,
          where: t.position < ^old_index and t.position >= ^new_index,
          update: [inc: [position: 1]]
        )
      end)
      |> multi_update_all(:position, fn %{index: new_index} ->
        from(t in Todo,
          where: t.id == ^todo.id,
          update: [set: [position: ^new_index]]
        )
      end)
  end

  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  def delete_todo(%Scope{} = _scope, %Todo{} = todo) do
    Repo.delete(todo)
  end

  def list_todos(%Scope{} = scope, limit) do
    Repo.all(
      from(t in Todo,
        where: t.user_id == ^scope.current_user.id,
        limit: ^limit,
        order_by: [asc: :inserted_at]
      )
    )
  end

  def get_todo!(id) do
    Todo
    |> Repo.get!(id)
    |> Repo.preload(:list)
  end

  def update_todo(%Scope{} = _scope, %Todo{} = todo, params) do
    todo
    |> Todo.changeset(params)
    |> Repo.update()
  end

  def create_todo(%Scope{} = scope, %List{} = list, params) do
    position = Repo.one(from t in Todo, where: t.list_id == ^list.id, select: count(t.id))

    todo = %Todo{
      user_id: scope.current_user.id,
      status: :started,
      position: position,
      list_id: list.id
    }

    Ecto.Multi.new()
    |> lock_list(list)
    |> Ecto.Multi.insert(:todo, Todo.changeset(todo, params))
    |> Repo.transaction()
    |> case do
      {:ok, %{todo: todo}} -> {:ok, todo}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Returns the list of lists.

  ## Examples

      iex> list_lists()
      [%List{}, ...]

  """
  def list_lists(%Scope{} = scope, limit) do
    from(l in List, where: l.user_id == ^scope.current_user.id, limit: ^limit)
    |> Repo.all()
    |> Repo.preload([:todos])
  end

  @doc """
  Gets a single list.

  Raises `Ecto.NoResultsError` if the List does not exist.

  ## Examples

      iex> get_list!(123)
      %List{}

      iex> get_list!(456)
      ** (Ecto.NoResultsError)

  """
  def get_list!(id) do
    List
    |> Repo.get!(id)
    |> preload()
  end

  defp preload(resource), do: Repo.preload(resource, [:todos])

  @doc """
  Creates a list.

  ## Examples

      iex> create_list(%{field: value})
      {:ok, %List{}}

      iex> create_list(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_list(%Scope{} = scope, attrs \\ %{}) do
    %List{user_id: scope.current_user.id}
    |> List.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a list.

  ## Examples

      iex> update_list(list, %{field: new_value})
      {:ok, %List{}}

      iex> update_list(list, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_list(%Scope{} = _scope, %List{} = list, attrs) do
    list
    |> List.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a list.

  ## Examples

      iex> delete_list(list)
      {:ok, %List{}}

      iex> delete_list(list)
      {:error, %Ecto.Changeset{}}

  """
  def delete_list(%Scope{} = _scope, %List{} = list) do
    Repo.delete(list)
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

  defp lock_list(%Ecto.Multi{} = multi, %List{} = list) do
    Repo.multi_transaction_lock(multi, :list, list.id)
  end

  defp lock_list(%Ecto.Multi{} = multi, %Todo{} = todo) do
    Repo.multi_transaction_lock(multi, :list, todo.list_id)
  end
end
