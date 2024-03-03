defmodule TodoTrek.Repo.Migrations.MakeTodosDeleteWhenListDeletes do
  use Ecto.Migration

  def up do
    drop constraint(:todos, "todos_list_id_fkey")

    alter table(:todos) do
      modify :list_id, references(:lists, on_delete: :delete_all)
    end
  end

  def down do
    drop constraint(:todos, "todos_list_id_fkey")

    alter table(:todos) do
      modify :list_id, references(:lists, on_delete: :nothing)
    end
  end
end
