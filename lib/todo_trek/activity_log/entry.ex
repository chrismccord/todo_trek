defmodule TodoTrek.EctoTypes.Stringable do
  use Ecto.Type

  @impl Ecto.Type
  def load(value), do: {:ok, value}

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(val) when is_atom(val),do: {:ok, Atom.to_string(val)}
  def cast(val) when is_binary(val), do: {:ok, val}
  def cast(val) when is_integer(val) or is_float(val), do: {:ok, to_string(val)}
  def cast(_), do: :error

  @impl Ecto.Type
  def dump(value) when is_binary(value) do
    {:ok, value}
  end

  def dump(_), do: :error
end

defmodule TodoTrek.ActivityLog.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activity_log_entries" do
    field :meta, :map, default: %{}
    field :action, :string
    field :performer_text, TodoTrek.EctoTypes.Stringable
    field :subject_text, TodoTrek.EctoTypes.Stringable
    field :before_text, TodoTrek.EctoTypes.Stringable
    field :after_text, TodoTrek.EctoTypes.Stringable

    belongs_to :todo, TodoTrek.Todos.Todo
    belongs_to :list, TodoTrek.Todos.List
    belongs_to :user, TodoTrek.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :meta,
      :action,
      :performer_text,
      :subject_text,
      :before_text,
      :after_text
    ])
    |> validate_required([:action, :performer_text, :subject_text])
  end
end
