defmodule TodoTrek.TodosTest do
  use TodoTrek.DataCase

  alias TodoTrek.Todos

  describe "lists" do
    setup :user_scope
    alias TodoTrek.Todos.List

    import TodoTrek.TodosFixtures

    @invalid_attrs %{title: nil}

    test "get_list!/1 returns the list with given id", %{scope: scope} do
      list = list_fixture(scope, %{})
      assert Todos.get_list!(scope, list.id) == list
    end

    test "create_list/1 with valid data creates a list", %{scope: scope} do
      valid_attrs = %{title: "some title"}

      assert {:ok, %List{} = list} = Todos.create_list(scope, valid_attrs)
      assert list.title == "some title"
    end

    test "create_list/1 with invalid data returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Todos.create_list(scope, @invalid_attrs)
    end

    test "update_list/2 with valid data updates the list", %{scope: scope} do
      list = list_fixture(scope, %{})
      update_attrs = %{title: "some updated title"}

      assert {:ok, %List{} = list} = Todos.update_list(scope, list, update_attrs)
      assert list.title == "some updated title"
    end

    test "update_list/2 with invalid data returns error changeset", %{scope: scope} do
      list = list_fixture(scope, %{})
      assert {:error, %Ecto.Changeset{}} = Todos.update_list(scope, list, @invalid_attrs)
      assert list == Todos.get_list!(scope, list.id)
    end

    test "delete_list/1 deletes the list", %{scope: scope} do
      list = list_fixture(scope, %{})
      assert {:ok, %List{}} = Todos.delete_list(scope, list)
      assert_raise Ecto.NoResultsError, fn -> Todos.get_list!(scope, list.id) end
    end

    test "change_list/1 returns a list changeset", %{scope: scope} do
      list = list_fixture(scope, %{})
      assert %Ecto.Changeset{} = Todos.change_list(list)
    end
  end
end
