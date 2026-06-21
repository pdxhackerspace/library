module OidcTestHelper
  OIDC_ENV_KEYS = %w[
    OIDC_ISSUER
    OIDC_CLIENT_ID
    OIDC_CLIENT_SECRET
    OIDC_REDIRECT_URI
    APP_BASE_URL
  ].freeze

  def with_oidc_env(**overrides)
    original = OIDC_ENV_KEYS.index_with { |key| ENV[key] }

    ENV['OIDC_ISSUER'] = overrides.fetch(:issuer, 'https://auth.example.com/application/o/library/')
    ENV['OIDC_CLIENT_ID'] = overrides.fetch(:client_id, 'client-id')
    ENV['OIDC_CLIENT_SECRET'] = overrides.fetch(:client_secret, 'client-secret')
    ENV['APP_BASE_URL'] = overrides.fetch(:app_base_url, 'http://www.example.com')
    ENV.delete('OIDC_REDIRECT_URI') unless overrides.key?(:redirect_uri)
    ENV['OIDC_REDIRECT_URI'] = overrides[:redirect_uri] if overrides.key?(:redirect_uri)

    yield
  ensure
    OIDC_ENV_KEYS.each do |key|
      if original[key].nil?
        ENV.delete(key)
      else
        ENV[key] = original[key]
      end
    end
  end
end
