module GuestAccessTestHelper
  def with_guest_subnets(*cidrs)
    original = ENV.fetch('GUEST_SUBNET_CIDRS', nil)
    ENV['GUEST_SUBNET_CIDRS'] = cidrs.join(',')
    yield
  ensure
    if original
      ENV['GUEST_SUBNET_CIDRS'] = original
    else
      ENV.delete('GUEST_SUBNET_CIDRS')
    end
  end

  def with_trusted_proxies(*entries)
    original = ENV.fetch('TRUSTED_PROXIES', nil)
    ENV['TRUSTED_PROXIES'] = entries.join(',')
    TrustedProxies.reset!
    Rails.application.config.action_dispatch.trusted_proxies = TrustedProxies.list
    yield
  ensure
    if original
      ENV['TRUSTED_PROXIES'] = original
    else
      ENV.delete('TRUSTED_PROXIES')
    end
    TrustedProxies.reset!
    Rails.application.config.action_dispatch.trusted_proxies = TrustedProxies.list
  end

  def with_trust_forwarded_headers(enabled)
    original = ENV.fetch('TRUST_FORWARDED_HEADERS', nil)
    ENV['TRUST_FORWARDED_HEADERS'] = enabled ? 'true' : 'false'
    yield
  ensure
    if original
      ENV['TRUST_FORWARDED_HEADERS'] = original
    else
      ENV.delete('TRUST_FORWARDED_HEADERS')
    end
  end

  def get_from_ip(path, ip, proxy: '127.0.0.1', **headers)
    env = { 'REMOTE_ADDR' => proxy, 'HTTP_X_FORWARDED_FOR' => ip }
    env.merge!(headers)
    get path, env: env
  end
end
