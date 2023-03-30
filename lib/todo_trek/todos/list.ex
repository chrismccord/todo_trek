defmodule TodoTrek.Todos.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :title, :string
    field :position, :integer

    has_many :todos, TodoTrek.Todos.Todo
    belongs_to :user, TodoTrek.Accounts.User

    embeds_many :email_notifications, EmailNotification, on_replace: :delete do
      field :email, :string
      field :name, :string
    end

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    attrs =
      case attrs do
        %{"email_notifications" => emails} ->
          email_notifications =
            emails
            |> Enum.filter(fn
              {_key, %{"_delete" => _}} -> false
              {_key, _} -> true
            end)
            |> Enum.map(fn
              {"@", "0"} -> {"-1", %{}}
              {"@", "-1"} -> {"9999", %{}}
              {"@", idx} -> {idx, %{}}
              {key, email} -> {key, email}
            end)
            |> Enum.sort_by(fn {idx, _email} ->
              {int, ""} = Integer.parse(idx)
              int
            end)
            |> Enum.with_index()
            |> Enum.into(%{}, fn {{_key, email}, idx} -> {to_string(idx), email} end)
            |> IO.inspect()

          Map.put(attrs, "email_notifications", email_notifications)

        %{} ->
          attrs
      end

    attrs =
      case attrs do
        %{"email_notifications" => emails, "reposition" => %{"new" => new_idx, "old" => old_idx}} ->
          {new_idx, ""} = Integer.parse(new_idx)
          {old_idx, ""} = Integer.parse(old_idx)

          emails =
            Enum.into(emails, %{}, fn {idx, params} ->
              {idx, ""} = Integer.parse(idx)

              cond do
                idx == old_idx -> {to_string(new_idx), params}
                idx > old_idx and idx <= new_idx -> {to_string(idx - 1), params}
                idx < old_idx and idx >= new_idx -> {to_string(idx + 1), params}
                true -> {to_string(idx), params}
              end
            end)

          Map.put(attrs, "email_notifications", emails)

        %{} ->
          attrs
      end

    list
    |> cast(attrs, [:title])
    |> cast_embed(:email_notifications, with: &email_changeset/2)
    |> validate_required([:title])
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
