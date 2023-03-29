defmodule TodoTrek.Lists.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :status, Ecto.Enum, values: [:started, :completed]
    field :title, :string
    field :body, :string

    belongs_to :list, TodoTrek.Lists.List

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:title, :status, :body])
    |> validate_required([:title])
    |> validate_length(:title, min: 3)
  end
end
