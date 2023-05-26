defmodule TodoTrek.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TodoTrekWeb.Telemetry,
      TodoTrek.Repo,
      {Phoenix.PubSub, name: TodoTrek.PubSub},
      {Finch, name: TodoTrek.Finch},
      TodoTrekWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TodoTrek.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TodoTrekWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
