defmodule Candy do
  import Phoenix.Controller
  import Plug.Conn

  defmacro __using__(_options) do
    quote do
      defdelegate fetch(conn, params), to: Candy
      defdelegate authorized(conn, params), to: Candy
    end
  end

  def fetch(conn, params) do
    param = params[:param] || "id"
    schema = params[:schema]
    cond do
      id = conn.params[param] ->
        name = schema
        |> Module.split
        |> List.last
        |> String.downcase
        |> String.to_atom

        repo = config(:repository)

        cond do
          object = repo.get(schema, id) ->
            assign(conn, name, object)
          true ->
            close(conn, 404)
        end
      true ->
        conn
    end
  end

  def authorized(conn, params) do
    cond do
      action_exempt?(conn, params) ->
        conn
      user = validate_auth(conn) ->
        action = action_name(conn)
        module = controller_module(conn)
        cond do
          module.can?(user, action, conn.assigns) ->
            assign(conn, :user, user)
          true ->
            close(conn, 403)
        end
      true ->
        close(conn, 401)
    end
  end

  defp validate_auth(conn) do
    config(:authorize).(conn)
  end

  defp close(conn, code) do
    errors = conn
    |> controller_module
    |> Module.split
    |> Enum.at(0)
    |> Module.concat(ErrorView)

    conn
    |> put_status(code)
    |> put_view(errors)
    |> render(:"#{code}")
    |> halt
  end

  defp action_exempt?(conn, params) do
    action = action_name(conn)
    cond do
      only = params[:only] ->
        !(action in only)
      except = params[:except] ->
        action in except
      true ->
        false
    end
  end

  defp config(key) do
    :candy
    |> Application.get_env(key)
    |> case do
      nil ->
        raise "Please configure #{key}"
      value -> value
    end
  end
end
