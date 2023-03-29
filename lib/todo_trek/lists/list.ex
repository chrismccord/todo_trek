defmodule TodoTrek.Lists.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :status, Ecto.Enum, values: [:started, :completed]
    field :title, :string

    has_many :cards, TodoTrek.Lists.Card, on_replace: :delete_if_exists

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    attrs =
      if attrs["cards"] == [""] do
        Map.put(attrs, "cards", [])
      else
        attrs
      end

    list
    |> cast(attrs, [:title, :status])
    |> cast_assoc(:cards, with: &TodoTrek.Lists.Card.changeset/2)
    |> validate_required([:title, :status])
  end
end
