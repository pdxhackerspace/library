require Rails.root.join('app/middleware/oidc_debug_middleware')

Rails.application.config.middleware.use OidcDebugMiddleware

Rails.application.config.after_initialize do
  next unless OidcDebug.enabled?

  OidcDebug.log_configuration

  next unless defined?(OpenIDConnect)

  OpenIDConnect.debug do |message|
    OidcDebug.log("HTTP: #{message}")
  end
end
