defmodule TodoTrek.Todos.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :title, :string
    field :position, :integer

    has_many :todos, TodoTrek.Todos.Todo
    belongs_to :user, TodoTrek.Accounts.User

    embeds_many :notifications, EmailNotification, on_replace: :delete do
      field :email, :string
      field :name, :string
    end

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> cast_embed(:notifications,
      with: &email_changeset/2,
      sort_param: :notifications_order,
      drop_param: :notifications_delete
    )
  end

  defp email_changeset(email, attrs) do
    email
    |> cast(attrs, [:email, :name])
    |> validate_required([:email])
  end
end
