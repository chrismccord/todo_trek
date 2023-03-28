defmodule Forms.Repo do
  use Ecto.Repo,
    otp_app: :forms,
    adapter: Ecto.Adapters.Postgres

  def multi_transaction_lock(multi, {scope, id}) when is_atom(scope) and is_integer(id) do
    Ecto.Multi.run(multi, scope, fn repo, _changes ->
      repo.query("SELECT pg_advisory_xact_lock(#{:erlang.phash2(scope)}, #{id})")
    end)
  end
end
