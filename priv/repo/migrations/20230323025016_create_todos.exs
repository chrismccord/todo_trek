defmodule TodoTrek.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :title, :string
      add :status, :string
      add :position, :integer, null: false
      add :list_id, references(:lists, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:todos, [:list_id])
  end
end
