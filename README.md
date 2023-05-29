# TodoTrek

A trello-like todo board which shows off different dynamic form strategies with Phoenix LiveView.

## Dynamic Forms

The logged-in home page is the main todo dashboard. It contains sortable Lists, which are stream-based and can be re-ordered. Within each list, Todos can be manged and re-ordered. Each todo is implemented as an individual form.

## Dynamic Nested Forms

The new List and edit List pages show examples of traditional nested forms with a dynamic `inputs_for` for List notifications. The notification entries can be prepended, appended, re-ordered, and deleted using regular checkboxes and Ecto's new `sort_param` and `drop_param` options to `cast_assoc` and `cast_embed`.

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies, and seed data
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * The default user is `user@example.com` with `password password` as the password.
  * Initial dummy data is seeded for the default user

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
