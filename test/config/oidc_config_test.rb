require 'test_helper'

class OidcConfigTest < ActiveSupport::TestCase
  setup do
    @keys = %w[OIDC_ISSUER OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_REDIRECT_URI APP_BASE_URL]
    @original = @keys.index_with { |key| ENV.fetch(key, nil) }
  end

  teardown do
    @keys.each do |key|
      if @original[key].nil?
        ENV.delete(key)
      else
        ENV[key] = @original[key]
      end
    end
  end

  test 'configured when credentials and app base url are set' do
    assign_oidc_env(
      issuer: 'https://auth.example.com/application/o/library/',
      client_id: 'client-id',
      client_secret: 'client-secret',
      app_base_url: 'http://localhost:3000'
    )

    assert OidcConfig.configured?
  end

  test 'configured when redirect uri is set explicitly' do
    assign_oidc_env(
      issuer: 'https://auth.example.com/application/o/library/',
      client_id: 'client-id',
      client_secret: 'client-secret',
      redirect_uri: 'http://localhost:3000/auth/oidc/callback'
    )

    assert OidcConfig.configured?
  end

  test 'not configured without credentials' do
    ENV.delete('OIDC_ISSUER')
    ENV.delete('OIDC_CLIENT_ID')
    ENV.delete('OIDC_CLIENT_SECRET')
    ENV['APP_BASE_URL'] = 'http://localhost:3000'

    assert_not OidcConfig.configured?
  end

  test 'not configured without redirect configuration' do
    assign_oidc_env(
      issuer: 'https://auth.example.com/application/o/library/',
      client_id: 'client-id',
      client_secret: 'client-secret'
    )
    ENV.delete('APP_BASE_URL')
    ENV.delete('OIDC_REDIRECT_URI')

    assert_not OidcConfig.configured?
  end

  test 'requested scopes include slack' do
    assert_includes OidcConfig.requested_scopes, 'slack'
  end

  private

  def assign_oidc_env(issuer:, client_id:, client_secret:, app_base_url: nil, redirect_uri: nil)
    ENV['OIDC_ISSUER'] = issuer
    ENV['OIDC_CLIENT_ID'] = client_id
    ENV['OIDC_CLIENT_SECRET'] = client_secret
    ENV['APP_BASE_URL'] = app_base_url if app_base_url
    ENV['OIDC_REDIRECT_URI'] = redirect_uri if redirect_uri
    ENV.delete('APP_BASE_URL') unless app_base_url
    ENV.delete('OIDC_REDIRECT_URI') unless redirect_uri
  end
end
