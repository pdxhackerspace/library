OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.logger = Rails.logger

if ENV['APP_BASE_URL'].present?
  OmniAuth.config.full_host = ENV['APP_BASE_URL']
end

Rails.application.config.middleware.use OmniAuth::Builder do
  next unless OidcConfig.configured?

  provider :openid_connect,
           name: :oidc,
           issuer: OidcConfig.issuer,
           discovery: true,
           scope: OidcConfig.requested_scopes,
           response_type: :code,
           pkce: true,
           client_options: {
             identifier: OidcConfig.client_id,
             secret: OidcConfig.client_secret,
             redirect_uri: OidcConfig.redirect_uri
           }
end
