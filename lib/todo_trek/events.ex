defmodule TodoTrek.Events do
  @moduledoc """
  Defines Event structs for use within the pubsub system.
  """
  defmodule ListAdded do
    defstruct list: nil, log: nil
  end

  defmodule ListUpdated do
    defstruct list: nil, log: nil
  end

  defmodule TodoAdded do
    defstruct todo: nil, log: nil
  end

  defmodule TodoUpdated do
    defstruct todo: nil, log: nil
  end

  defmodule TodoDeleted do
    defstruct todo: nil, log: nil
  end

  defmodule TodoRepositioned do
    defstruct todo: nil, log: nil
  end

  defmodule TodoMoved do
    defstruct todo: nil, from_list_id: nil, to_list_id: nil, log: nil
  end

  defmodule ListRepositioned do
    defstruct list: nil, log: nil
  end

  defmodule TodoToggled do
    defstruct todo: nil, log: nil
  end

  defmodule ListDeleted do
    defstruct list: nil, log: nil
  end
end
