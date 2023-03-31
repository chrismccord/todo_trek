defmodule TodoTrek.Todos.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :title, :string
    field :whatever, :string, virtual: true
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
    attrs =
      case attrs do
        %{"notifications" => notifications} ->
          deletes = attrs["notifications_delete"] || []
          filtered_notifications = Map.drop(notifications, deletes)

          sorted_notifications =
            case attrs do
              %{"notifications_order" => order} ->
                Enum.reduce(order, %{}, fn idx_str, acc ->
                  cond do
                    idx_str in deletes -> acc
                    data = filtered_notifications[idx_str] -> Map.put(acc, map_size(acc), data)
                    true -> Map.put(acc, map_size(acc), %{})
                  end
                end)

              %{} ->
                filtered_notifications
            end

          Map.put(attrs, "notifications", sorted_notifications)

        %{} ->
          attrs
      end

    list
    |> cast(attrs, [:title, :whatever])
    |> cast_embed(:notifications,
      with: &email_changeset/2,
      sort_param: "notifications_order",
      delete_param: "notifications_delete"
    )
    |> validate_required([:title, :whatever])
  end

  defp email_changeset(email, attrs) do
    # if attrs["_delete"] do
    #   email
    #   |> cast(attrs, [:email, :name])
    #   |> validate_required([:email])
    #   |> Map.put(:action, :delete)
    #   |> IO.inspect()
    # else
    email
    |> cast(attrs, [:email, :name])
    |> validate_required([:email])

    # end
  end
end
