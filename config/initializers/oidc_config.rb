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
end
