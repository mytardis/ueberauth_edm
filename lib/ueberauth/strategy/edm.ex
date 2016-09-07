defmodule Ueberauth.Strategy.EDM do
  @moduledoc """
  EDM Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :sub, default_scope: "openid profile email", hd: nil

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  import Logger, except: [error: 2]

  @doc """
  Handles initial request for EDM authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    Logger.debug "These are the requested scopes: " <> scopes
    opts = [ scope: scopes ]
    opts = if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts
    opts = if option(conn, :hd), do: Keyword.put(opts, :hd, option(conn, :hd)), else: opts
    opts = Keyword.put(opts, :redirect_uri, callback_url(conn))
    Logger.debug "OAuth2 request URL: " <> Ueberauth.Strategy.EDM.OAuth.authorize_url!(opts)
    redirect!(conn, Ueberauth.Strategy.EDM.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from EDM auth.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.EDM.OAuth.get_token!([code: code], opts)
    Logger.debug "This is the token:"
    Logger.debug inspect(token)
    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:edm_user, nil)
    |> put_private(:edm_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.edm_user[uid_field]
  end

  @doc """
  Includes the credentials from the edm response.
  """
  def credentials(conn) do
    token = conn.private.edm_token
    scopes = (token.other_params["scope"] || "")
              |> String.split(",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.edm_user

    %Info{
      email: user["email"],
      first_name: user["given_name"],
      image: user["picture"],
      last_name: user["family_name"],
      name: user["name"],
      urls: %{
        profile: user["profile"],
        website: user["hd"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the EDM auth callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.edm_token,
        user: conn.private.edm_user
      }
    }
  end


  defp fetch_user(conn, token) do
    conn = put_private(conn, :edm_token, token)

    path = Ueberauth.Strategy.EDM.OAuth.load_discovery_url()
            |> Keyword.get(:userinfo_endpoint)
    resp = OAuth2.AccessToken.get(token, path)
    Logger.debug "This is the data from the user info endpoint:"
    Logger.debug inspect(resp)
    case resp do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :edm_user, user)
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end
end
