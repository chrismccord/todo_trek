defmodule TodoTrekWeb.ListLive.FormComponent do
  use TodoTrekWeb, :live_component

  alias TodoTrek.Todos

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header><%= @title %></.header>
      <.simple_form
        for={@form}
        id="list-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-2">
          <.input field={@form[:title]} type="text" />

          <.insert_inputs_for field={@form[:email_notifications]} at={0}>
            Prepend
          </.insert_inputs_for>

          <.inputs_for field={@form[:email_notifications]}></.inputs_for>
          <div id="notifications" phx-hook="SortableInputsFor" class="space-y-2">
            <.inputs_for :let={{f_nested, idx}} field={@form[:email_notifications]} skip_hidden sort_param="email_order">
              <div class="flex space-x-2">
                <.delete_inputs_for field={f_nested}>
                  <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                </.delete_inputs_for>
                <.input type="text" field={f_nested[:email]} placeholder="email" />
                <.input type="text" field={f_nested[:name]} placeholderj="name" />
                <input hidden name={"#{@form[:email_notifications_order].name}[]"} value={f_nested[:]} />
              </div>
            </.inputs_for>
          </div>

          <.insert_inputs_for field={@form[:email_notifications]}>
            Append
          </.insert_inputs_for>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." phx-click={hide_modal("list-modal")}>
            Save List
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{list: list} = assigns, socket) do
    changeset = Todos.change_list(list)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"list" => list_params}, socket) do
    changeset =
      socket.assigns.list
      |> Todos.change_list(list_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"list" => list_params}, socket) do
    save_list(socket, socket.assigns.action, list_params)
  end

  defp save_list(socket, :edit_list, list_params) do
    case Todos.update_list(socket.assigns.scope, socket.assigns.list, list_params) do
      {:ok, _list} ->
        {:noreply,
         socket
         |> put_flash(:info, "List updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_list(socket, :new_list, list_params) do
    case Todos.create_list(socket.assigns.scope, list_params) do
      {:ok, _list} ->
        {:noreply,
         socket
         |> put_flash(:info, "List created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    if changeset.data.email_notifications == [] do
      email = %Todos.List.EmailNotification{}
      changeset = Ecto.Changeset.put_change(changeset, :email_notifications, [email])
      assign(socket, :form, to_form(changeset))
    else
      assign(socket, :form, to_form(changeset))
    end
  end
end
