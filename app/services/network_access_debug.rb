module NetworkAccessDebug
  module_function

  def enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('NETWORK_ACCESS_DEBUG', 'false'))
  end

  def log_decision(request, evaluation)
    return unless enabled?

    message = "[NetworkAccess] #{request.request_method} #{request.fullpath}:\n"
    message += JSON.pretty_generate(payload(request, evaluation))
    Rails.logger.info(message)
  end

  def payload(request, evaluation)
    {
      decision: {
        on_space: evaluation[:on_space],
        reason: evaluation[:reason],
        matching_cidr: evaluation[:matching_cidr]
      },
      resolved_client_ip: request.remote_ip,
      proxy: proxy_info(request),
      guest_subnet_cidrs: NetworkAccess.guest_subnet_labels,
      guest_subnet_cidrs_env: ENV.fetch('GUEST_SUBNET_CIDRS', ''),
      trusted_proxies: trusted_proxies.map(&:to_s),
      trusted_proxies_env: ENV.fetch('TRUSTED_PROXIES', '')
    }
  end

  def proxy_info(request)
    {
      remote_addr: request.get_header('REMOTE_ADDR'),
      x_forwarded_for: request.get_header('HTTP_X_FORWARDED_FOR'),
      x_real_ip: request.get_header('HTTP_X_REAL_IP'),
      forwarded: request.get_header('HTTP_FORWARDED'),
      x_forwarded_proto: request.get_header('HTTP_X_FORWARDED_PROTO'),
      x_forwarded_host: request.get_header('HTTP_X_FORWARDED_HOST'),
      x_forwarded_port: request.get_header('HTTP_X_FORWARDED_PORT')
    }.compact
  end

  def trusted_proxies
    Rails.application.config.action_dispatch.trusted_proxies.presence ||
      ActionDispatch::RemoteIp::TRUSTED_PROXIES
  end
end
