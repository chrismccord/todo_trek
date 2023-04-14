defmodule TodoTrekWeb.Timeline do
  use TodoTrekWeb, :html

  alias TodoTrek.ActivityLog

  attr :stream, :any, required: true
  attr :page, :integer, required: true
  attr :end_of_timeline?, :boolean, required: true

  def activity_logs(assigns) do
    ~H"""
    <span
      :if={@page > 1}
      class="text-3xl fixed bottom-2 right-2 bg-zinc-900 text-white rounded-lg p-3 text-center min-w-[65px] z-50 opacity-80"
    >
      <span class="text-sm">pg</span>
      <%= @page %>
    </span>

    <ul
      id="activity"
      phx-update="stream"
      phx-viewport-top={@page > 1 && "prev-page"}
      phx-viewport-bottom={!@end_of_timeline? && "next-page"}
      phx-page-loading
      class={[
        if(@end_of_timeline?, do: "pb-10", else: "pb-[calc(200vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]")
      ]}
    >
      <li :for={{id, entry} <- @stream} id={id}>
        <.activity_entry action={entry.action} entry={entry} />
      </li>
    </ul>
    <div :if={@end_of_timeline?} class="mt-5 text-[50px] text-center">
      🎉 You made it to the beginning of time 🎉
    </div>
    """
  end

  attr :action, :string, required: true
  attr :entry, ActivityLog.Entry, required: true

  defp activity_entry(%{action: "list_position_updated"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-arrows-up-down" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> repositioned list "<%= @entry.subject_text %>"
              from <span class="font-medium text-gray-900"><%= @entry.before_text %></span>
              to <span class="font-medium text-gray-900"><%= @entry.after_text %></span>
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "todo_position_updated"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-arrows-up-down" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> repositioned todo "<%= @entry.subject_text %>"
              from <span class="font-medium text-gray-900"><%= @entry.before_text %></span>
              to <span class="font-medium text-gray-900"><%= @entry.after_text %></span>
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "todo_moved"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-arrows-right-left" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> moved todo "<%= @entry.subject_text %>"
              from list <span class="font-medium text-gray-900">"<%= @entry.before_text %>"</span>
              to list <span class="font-medium text-gray-900">"<%= @entry.after_text %>"</span>
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "todo_deleted"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-red-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-archive-box-x-mark" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> deleted todo "<%= @entry.subject_text %>"
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "todo_toggled"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span
            :if={@entry.after_text == "completed"}
            class="h-8 w-8 rounded-full bg-green-400 flex items-center justify-center ring-8 ring-white"
          >
            <.icon name="hero-check-circle" class="w-5 h-5 text-white" />
          </span>
          <span
            :if={@entry.after_text != "completed"}
            class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white"
          >
            <.icon name="hero-arrow-uturn-down" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> toggled todo "<%= @entry.subject_text %>"
              from <span class="font-medium text-gray-900"><%= @entry.before_text %></span>
              to <span class="font-medium text-gray-900"><%= @entry.after_text %></span>
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "todo_updated"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-check-circle" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> updated todo "<%= @entry.subject_text %>"
              to <span class="font-medium text-gray-900">"<%= @entry.after_text %>"</span>
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "todo_created"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-green-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-plus" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> created new todo "<%= @entry.subject_text %>"
              on list
              "<%= @entry.after_text %>"
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "list_created"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-green-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-plus" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> created new list "<%= @entry.subject_text %>"
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "list_updated"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-check-circle" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> updated list "<%= @entry.subject_text %>"
              to <span class="font-medium text-gray-900">"<%= @entry.after_text %>"</span>
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp activity_entry(%{action: "list_deleted"} = assigns) do
    ~H"""
    <div class="relative pb-32">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="h-8 w-8 rounded-full bg-red-400 flex items-center justify-center ring-8 ring-white">
            <.icon name="hero-archive-box-x-mark" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
          <div>
            <p class="text-sm text-gray-500">
              <%= @entry.performer_text %> deleted list "<%= @entry.subject_text %>"
            </p>
          </div>
          <div class="whitespace-nowrap text-right text-sm text-gray-500">
            <.local_time id={@entry.id} at={@entry.inserted_at} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :at, :any, required: true
  attr :id, :any, required: true

  def local_time(assigns) do
    ~H"""
    <time phx-hook="LocalTime" id={"time-#{@id}"} class="invisible"><%= @at %></time>
    """
  end
end
