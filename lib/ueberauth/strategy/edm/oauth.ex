defmodule Ueberauth.Strategy.EDM.OAuth do
  @moduledoc """
  OAuth2 for EDM.

  Add `client_id` and `client_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.EDM.OAuth,
    client_id: System.get_env("GOOGLE_APP_ID"),
    client_secret: System.get_env("GOOGLE_APP_SECRET")
  """
  use OAuth2.Strategy
  import Logger

  @defaults [
     strategy: __MODULE__,
     discovery_url: "http://localhost:5000/.well-known/openid-configuration"
   ]

  @doc """
  Construct a client for requests to EDM.

  This will be setup automatically for you in `Ueberauth.Strategy.EDM`.

  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.EDM.OAuth)

    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)
    opts = opts |> Keyword.merge(load_discovery_url(opts))
    opts = opts |> Keyword.merge([authorize_url: Keyword.get(opts, :authorization_endpoint)])
                |> Keyword.merge([token_url: Keyword.get(opts, :token_endpoint)])
    Logger.debug inspect(opts)
    OAuth2.Client.new(opts)
  end

  defp load_discovery_url(opts) do
    case Keyword.get(opts, :discovery_url) do
      nil ->
        Logger.warn "No discovery URL specified"
        []
      url ->
        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            body |> Poison.decode!
                 |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)
          {_, %HTTPoison.Response{status_code: code, body: body}} ->
            Logger.warn "Could not fetch discovery url: Status code #{code}, content: #{body}"
            []
        end
    end
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.get_token!(params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
