ClientIpResolution = Data.define(:ip, :source, :direct_ip)

module RequestClientIp
  module_function

  def resolve(request)
    direct_ip = request.get_header('REMOTE_ADDR').to_s
    rails_ip = ActionDispatch::RemoteIp::GetIp.new(request, false, TrustedProxies.list).to_s

    return ClientIpResolution.new(rails_ip, 'remote_ip', direct_ip) if rails_ip != direct_ip

    if parse_forwarded_headers?(direct_ip)
      forwarded = from_forwarded_headers(request)
      return ClientIpResolution.new(forwarded[:ip], forwarded[:source], direct_ip) if forwarded
    end

    ClientIpResolution.new(rails_ip, 'remote_addr', direct_ip)
  end

  def parse_forwarded_headers?(direct_ip)
    TrustedProxies.trusted?(direct_ip) || trust_forwarded_headers?
  end

  def trust_forwarded_headers?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('TRUST_FORWARDED_HEADERS', 'false'))
  end

  def from_forwarded_headers(request)
    from_header(request.get_header('HTTP_X_REAL_IP'), 'x_real_ip') ||
      from_x_forwarded_for_leftmost(request.get_header('HTTP_X_FORWARDED_FOR')) ||
      from_configured_header(request)
  end

  def from_x_forwarded_for_leftmost(header)
    ips = split_ips(header)
    return if ips.empty?

    { ip: ips.first, source: 'x_forwarded_for' }
  end

  def from_header(header, source)
    ip = normalize_ip(header)
    return unless ip

    { ip: ip, source: source }
  end

  def from_configured_header(request)
    header_name = ENV.fetch('CLIENT_IP_HEADER', '').strip
    return if header_name.blank?

    env_key = "HTTP_#{header_name.tr('-', '_').upcase}"
    from_header(request.get_header(env_key), 'client_ip_header')
  end

  def split_ips(header)
    header.to_s.split(',').filter_map { |part| normalize_ip(part) }
  end

  def normalize_ip(value)
    ip = value.to_s.strip
    return if ip.blank?

    IPAddr.new(ip).to_s
  rescue IPAddr::InvalidAddressError
    nil
  end
end
