defmodule Forms.Repo do
  use Ecto.Repo,
    otp_app: :forms,
    adapter: Ecto.Adapters.Postgres
end
