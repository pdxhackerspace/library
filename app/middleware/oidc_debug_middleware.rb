class OidcDebugMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    OidcDebug.log_request(env) if OidcDebug.enabled? && oidc_path?(env)

    status, headers, response = @app.call(env)
    OidcDebug.log_failure(env) if OidcDebug.enabled? && omniauth_failure?(env)

    [status, headers, response]
  end

  private

  def oidc_path?(env)
    env['PATH_INFO'].to_s.start_with?('/auth/oidc')
  end

  def omniauth_failure?(env)
    env['PATH_INFO'].to_s == '/auth/failure'
  end
end
