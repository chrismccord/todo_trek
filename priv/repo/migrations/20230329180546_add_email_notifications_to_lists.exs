defmodule TodoTrek.Repo.Migrations.AddEmailNotificationsToLists do
  use Ecto.Migration

  def change do
    alter table(:lists) do
      add :notifications, {:array, :map}, null: false, default: []
    end
  end
end
