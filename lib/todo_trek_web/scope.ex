defmodule TodoTrekWeb.Scope do
  def on_mount(:default, _params, _session, socket) do
    {:cont,
     Phoenix.Component.assign(socket, :scope, %TodoTrek.Scope{
       current_user: socket.assigns[:current_user]
     })}
  end
end
