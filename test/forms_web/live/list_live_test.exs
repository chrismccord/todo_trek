defmodule FormsWeb.ListLiveTest do
  use FormsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Forms.TodosFixtures

  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  defp create_list(_) do
    list = list_fixture()
    %{list: list}
  end

  describe "Index" do
    setup [:create_list]

    test "lists all lists", %{conn: conn, list: list} do
      {:ok, _index_live, html} = live(conn, ~p"/lists")

      assert html =~ "Listing Lists"
      assert html =~ list.title
    end

    test "saves new list", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/lists")

      assert index_live |> element("a", "New List") |> render_click() =~
               "New List"

      assert_patch(index_live, ~p"/lists/new")

      assert index_live
             |> form("#list-form", list: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#list-form", list: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/lists")

      html = render(index_live)
      assert html =~ "List created successfully"
      assert html =~ "some title"
    end

    test "updates list in listing", %{conn: conn, list: list} do
      {:ok, index_live, _html} = live(conn, ~p"/lists")

      assert index_live |> element("#lists-#{list.id} a", "Edit") |> render_click() =~
               "Edit List"

      assert_patch(index_live, ~p"/lists/#{list}/edit")

      assert index_live
             |> form("#list-form", list: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#list-form", list: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/lists")

      html = render(index_live)
      assert html =~ "List updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes list in listing", %{conn: conn, list: list} do
      {:ok, index_live, _html} = live(conn, ~p"/lists")

      assert index_live |> element("#lists-#{list.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#lists-#{list.id}")
    end
  end

  describe "Show" do
    setup [:create_list]

    test "displays list", %{conn: conn, list: list} do
      {:ok, _show_live, html} = live(conn, ~p"/lists/#{list}")

      assert html =~ "Show List"
      assert html =~ list.title
    end

    test "updates list within modal", %{conn: conn, list: list} do
      {:ok, show_live, _html} = live(conn, ~p"/lists/#{list}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit List"

      assert_patch(show_live, ~p"/lists/#{list}/show/edit")

      assert show_live
             |> form("#list-form", list: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#list-form", list: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/lists/#{list}")

      html = render(show_live)
      assert html =~ "List updated successfully"
      assert html =~ "some updated title"
    end
  end
end
