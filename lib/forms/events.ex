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

  defmodule ListRepositioned do
    defstruct list: nil
  end

  defmodule TodoToggled do
    defstruct todo: nil
  end
end
