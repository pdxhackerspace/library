module TrustedProxies
  module_function

  def list
    @list ||= build_list
  end

  def reset!
    @list = nil
  end

  def custom_configured?
    ENV.fetch('TRUSTED_PROXIES', '').present?
  end

  def trusted?(ip_string)
    return false if ip_string.blank?

    ip = IPAddr.new(ip_string.to_s.strip)
    list.any? { |proxy| proxy.include?(ip) }
  rescue IPAddr::InvalidAddressError
    false
  end

  def build_list
    ActionDispatch::RemoteIp::TRUSTED_PROXIES + parse_env(ENV.fetch('TRUSTED_PROXIES', ''))
  end

  def parse_env(value)
    value.split(',').filter_map do |entry|
      label = entry.strip
      next if label.blank?

      IPAddr.new(label)
    end
  rescue IPAddr::InvalidAddressError
    []
  end
end
