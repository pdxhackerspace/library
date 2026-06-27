class ClientIpMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    resolution = RequestClientIp.resolve(request)
    env['action_dispatch.remote_ip'] = resolution.ip
    env['action_dispatch.client_ip_source'] = resolution.source
    env['action_dispatch.client_ip_direct'] = resolution.direct_ip

    @app.call(env)
  end
end
