defmodule Forms.Events do
  defmodule ListAdded do
    defstruct list: nil
  end

  defmodule ListUpdated do
    defstruct list: nil
  end

  defmodule TodoAdded do
    defstruct todo: nil
  end

  defmodule TodoUpdated do
    defstruct todo: nil
  end

  defmodule TodoDeleted do
    defstruct todo: nil
  end

  defmodule TodoRepositioned do
    defstruct todo: nil
  end

  defmodule TodoMoved do
    defstruct todo: nil, from_list_id: nil, to_list_id: nil
  end

  defmodule ListRepositioned do
    defstruct list: nil
  end

  defmodule TodoToggled do
    defstruct todo: nil
  end
end
