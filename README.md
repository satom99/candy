# Candy

Resource authorization for [Phoenix](https://github.com/phoenixframework/phoenix).

### Configuration

```elixir
config :candy,
[
  repository: Example.Repo,
  authorize: &Example.Cookie.verify/1
]
```

### Example

```elixir
defmodule Example.Cookie do
  # ···
  alias Example.Models.User

  def verify(_conn) do
    %User{}
  end
end

defmodule Example.Routes.Post do
  use Phoenix.Controller
  use Candy

  alias Example.Models.Post

  plug :fetch, schema: Post, param: "id"
  plug :authorized, except: [:index]

  def index(conn, params) do
    post = conn.assigns.post
    # ···
  end

  def update(conn, params) do
    post = conn.assigns.post
    user = conn.assigns.user
    # ···
  end

  def can?(user, :update, resources) do
    post = resources.post
    post.author_id == user.id
  end
end
```
