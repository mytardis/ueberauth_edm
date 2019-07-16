defmodule UeberauthEdmTest do
  use ExUnit.Case
  use Plug.Test
  import Mock
  import Ueberauth.Strategy.EDM, only: [handle_request!: 1]

  setup do
    Application.put_env(:ueberauth, Ueberauth.Strategy.EDM.OAuth, client_id: "whatever")
  end

  describe "handle_request!/1" do
    test "redirect to the authorize_url containing the provided organization_domain" do
      conn =
        conn(:get, "/", %{scope: "openid email", organization_domain: "custom_org_domain"})
        |> Map.put(:private, %{ueberauth_request_options: %{options: [{:state, "admin"}]}})

      with_mock HTTPoison,
        get: fn _discovery_url ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               "{\"token_endpoint\":\"https://token_endpoint.wtf\",\"authorization_endpoint\":\"https://authorize_url.wtf\"}"
           }}
        end do
        resp = handle_request!(conn)

        assert resp.status == 302

        assert resp.resp_headers == [
                 {"cache-control", "max-age=0, private, must-revalidate"},
                 {"location",
                  "/oauth/authorize?client_id=whatever&organization_domain=custom_org_domain&redirect_uri=http%3A%2F%2Fwww.example.com&response_type=code&scope=openid+email"}
               ]
      end
    end

    test "redirect to the authorize_url even without an organization_domain" do
      conn =
        conn(:get, "/", %{scope: "openid email"})
        |> Map.put(:private, %{ueberauth_request_options: %{options: [{:state, "admin"}]}})

      with_mock HTTPoison,
        get: fn _discovery_url ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               "{\"token_endpoint\":\"https://token_endpoint.wtf\",\"authorization_endpoint\":\"https://authorize_url.wtf\"}"
           }}
        end do
        resp = handle_request!(conn)

        assert resp.status == 302

        assert resp.resp_headers == [
                 {"cache-control", "max-age=0, private, must-revalidate"},
                 {"location",
                  "/oauth/authorize?client_id=whatever&redirect_uri=http%3A%2F%2Fwww.example.com&response_type=code&scope=openid+email"}
               ]
      end
    end
  end
end
