defmodule TodoTrek.TodosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoTrek.Todos` context.
  """

  @doc """
  Generate a list.
  """
  def list_fixture(attrs \\ %{}) do
    {:ok, list} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> TodoTrek.Todos.create_list()

    list
  end
end
