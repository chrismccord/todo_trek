defmodule TodoTrek.Scope do
  defstruct current_user: nil, current_user_id: nil

  def for_user(nil) do
    %__MODULE__{current_user: nil, current_user_id: nil}
  end

  def for_user(%TodoTrek.Accounts.User{} = user) do
    %__MODULE__{current_user: user, current_user_id: user.id}
  end
end
