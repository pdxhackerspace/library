module OidcConfig
  module_function

  def issuer
    ENV.fetch('OIDC_ISSUER', nil)
  end

  def client_id
    ENV.fetch('OIDC_CLIENT_ID', nil)
  end

  def client_secret
    ENV.fetch('OIDC_CLIENT_SECRET', nil)
  end

  def redirect_uri
    ENV['OIDC_REDIRECT_URI'].presence ||
      File.join(ENV.fetch('APP_BASE_URL', ''), '/auth/oidc/callback').presence
  end

  def configured?
    issuer.present? &&
      client_id.present? &&
      client_secret.present? &&
      redirect_configured?
  end

  def redirect_configured?
    ENV['OIDC_REDIRECT_URI'].present? || ENV['APP_BASE_URL'].present?
  end

  def requested_scopes
    (%w[openid email profile] + admin_scopes + editor_scopes).uniq
  end

  def admin_scopes
    scope_names('OIDC_ADMIN_SCOPES', %w[is_admin])
  end

  def editor_scopes
    scope_names('OIDC_EDITOR_SCOPES', %w[is_editor])
  end

  def scope_names(env_key, defaults)
    ENV.fetch(env_key, defaults.join(',')).split(',').map(&:strip).compact_blank
  end
end
