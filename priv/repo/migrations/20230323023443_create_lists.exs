defmodule Forms.Repo.Migrations.CreateLists do
  use Ecto.Migration

  def change do
    create table(:lists) do
      add :title, :string

      timestamps()
    end
  end
end
