defmodule Forms.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :status, :string
      add :list_id, references(:lists, on_delete: :nothing)

      timestamps()
    end

    create index(:todos, [:list_id])
  end
end
