module OidcTestHelper
  OIDC_ENV_KEYS = %w[
    OIDC_ISSUER
    OIDC_CLIENT_ID
    OIDC_CLIENT_SECRET
    OIDC_REDIRECT_URI
    APP_BASE_URL
    OIDC_ADMIN_SCOPES
    OIDC_EDITOR_SCOPES
  ].freeze

  def with_oidc_env(**overrides)
    original = snapshot_env(OIDC_ENV_KEYS)
    apply_oidc_env(overrides)
    yield
  ensure
    restore_env(original)
  end

  def with_scope_env(overrides)
    original = snapshot_env(overrides.keys)
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    restore_env(original)
  end

  def omniauth_auth(scopes: %w[openid email profile], uid: '123', email: 'oidc@example.com', raw_info: {},
                    id_token_payload: nil)
    info = Struct.new(:email, :name).new(email, 'OIDC User')
    extra = Struct.new(:raw_info).new(raw_info)
    payload = id_token_payload || {}
    credentials = Struct.new(:id_token, :scope).new(
      payload.present? ? encode_jwt(payload) : nil,
      Array(scopes).join(' ')
    )

    Struct.new(:provider, :uid, :info, :extra, :credentials).new('oidc', uid, info, extra, credentials)
  end

  def encode_jwt(payload)
    header = Base64.urlsafe_encode64({ alg: 'none', typ: 'JWT' }.to_json, padding: false)
    body = Base64.urlsafe_encode64(payload.to_json, padding: false)

    "#{header}.#{body}."
  end

  private

  def snapshot_env(keys)
    keys.index_with { |key| ENV.fetch(key, nil) }
  end

  def apply_oidc_env(overrides)
    ENV['OIDC_ISSUER'] = overrides.fetch(:issuer, 'https://auth.example.com/application/o/library/')
    ENV['OIDC_CLIENT_ID'] = overrides.fetch(:client_id, 'client-id')
    ENV['OIDC_CLIENT_SECRET'] = overrides.fetch(:client_secret, 'client-secret')
    ENV['APP_BASE_URL'] = overrides.fetch(:app_base_url, 'http://www.example.com')
    ENV.delete('OIDC_REDIRECT_URI') unless overrides.key?(:redirect_uri)
    ENV['OIDC_REDIRECT_URI'] = overrides[:redirect_uri] if overrides.key?(:redirect_uri)
  end

  def restore_env(original)
    original.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end
