defmodule Forms.Repo.Migrations.CreateLists do
  use Ecto.Migration

  def change do
    create table(:lists) do
      add :title, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :position, :integer, null: false

      timestamps()
    end
  end
end
