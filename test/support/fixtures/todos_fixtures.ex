defmodule TodoTrek.TodosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoTrek.Todos` context.
  """

  @doc """
  Generate a list.
  """
  def list_fixture(attrs \\ %{}) do
    list_fixture(TodoTrek.AccountsFixtures.user_scope(), attrs)
  end

  def list_fixture(%TodoTrek.Scope{} = scope, attrs) do
    attrs = Enum.into(attrs, %{
        title: "some title"
      })

    {:ok, list} = TodoTrek.Todos.create_list(scope, attrs)

    list
  end
end
