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

  def admin_claim_keys
    claim_keys('OIDC_ADMIN_CLAIMS', %w[is_admin admin])
  end

  def editor_claim_keys
    claim_keys('OIDC_EDITOR_CLAIMS', %w[is_editor editor])
  end

  def admin_groups
    group_names('OIDC_ADMIN_GROUPS')
  end

  def editor_groups
    group_names('OIDC_EDITOR_GROUPS')
  end

  def claim_keys(env_key, defaults)
    ENV.fetch(env_key, defaults.join(',')).split(',').map(&:strip).compact_blank
  end

  def group_names(env_key)
    ENV.fetch(env_key, '').split(',').map(&:strip).compact_blank
  end
end
