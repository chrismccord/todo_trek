defmodule Forms.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "todos" do
    field :status, Ecto.Enum, values: [:started, :completed]
    field :title, :string
    field :list_id, :id

    timestamps()
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:id, :title, :status])
    |> validate_required([:title, :status])
  end
end
