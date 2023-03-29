defmodule TodoTrek.Repo do
  use Ecto.Repo,
    otp_app: :todo_trek,
    adapter: Ecto.Adapters.Postgres

  def multi_transaction_lock(multi, name, {scope, id}) when is_atom(scope) and is_integer(id) do
    Ecto.Multi.run(multi, name, fn repo, _changes ->
      repo.query("SELECT pg_advisory_xact_lock(#{:erlang.phash2(scope)}, #{id})")
    end)
  end

  def multi_transaction_lock(multi, name, %struct{id: id}) when is_integer(id) do
    multi_transaction_lock(multi, name, {struct, id})
  end
end
