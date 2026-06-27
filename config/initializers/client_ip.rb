require Rails.root.join('app/middleware/client_ip_middleware')
require Rails.root.join('app/services/trusted_proxies')
require Rails.root.join('app/services/request_client_ip')

Rails.application.config.action_dispatch.trusted_proxies = TrustedProxies.list
Rails.application.config.middleware.insert_after ActionDispatch::RemoteIp, ClientIpMiddleware
