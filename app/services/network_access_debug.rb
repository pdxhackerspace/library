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
    resolution = RequestClientIp.resolve(request)

    {
      decision: decision_payload(evaluation),
      resolved_client_ip: resolution.ip,
      client_ip_source: resolution.source,
      direct_connection_ip: resolution.direct_ip,
      proxy: proxy_info(request),
      **network_config_payload
    }
  end

  def decision_payload(evaluation)
    {
      on_space: evaluation[:on_space],
      reason: evaluation[:reason],
      matching_cidr: evaluation[:matching_cidr]
    }
  end

  def network_config_payload
    {
      guest_subnet_cidrs: NetworkAccess.guest_subnet_labels,
      guest_subnet_cidrs_env: ENV.fetch('GUEST_SUBNET_CIDRS', ''),
      trusted_proxies: TrustedProxies.list.map(&:to_s),
      trusted_proxies_env: ENV.fetch('TRUSTED_PROXIES', ''),
      trust_forwarded_headers: RequestClientIp.trust_forwarded_headers?
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
end
