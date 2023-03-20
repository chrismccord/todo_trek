defmodule Forms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FormsWeb.Telemetry,
      # Start the Ecto repository
      Forms.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Forms.PubSub},
      # Start Finch
      {Finch, name: Forms.Finch},
      # Start the Endpoint (http/https)
      FormsWeb.Endpoint
      # Start a worker by calling: Forms.Worker.start_link(arg)
      # {Forms.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Forms.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FormsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
