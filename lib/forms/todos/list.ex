defmodule Forms.Todos.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :title, :string

    has_many :todos, Forms.Todos.Todo
    belongs_to :user, Forms.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    todos = for({key, todo} <- attrs["todos"] || %{}, !todo["_delete"], into: %{}, do: {key, todo})
    attrs = Map.put(attrs, "todos", todos)

    list
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
