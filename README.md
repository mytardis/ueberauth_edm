# Überauth EDM

> EDM OpenID Connect OAuth2 strategy for Überauth.

## Installation

1. Setup the OpenID Connect auth server

1. Add `:ueberauth_edm` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_edm, git: "https://github.com/mytardis/ueberauth_edm.git"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_edm]]
    end
    ```

1. Add EDM to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        edm: {Ueberauth.Strategy.EDM, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.EDM.OAuth,
      client_id: System.get_env("EDM_CLIENT_ID"),
      client_secret: System.get_env("EDM_CLIENT_SECRET")
      discovery_url: System.get_env("EDM_DISCOVERY_URL")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/edm

## License

Please see [LICENSE](https://github.com/ueberauth/ueberauth_google/blob/master/LICENSE) for licensing details.
