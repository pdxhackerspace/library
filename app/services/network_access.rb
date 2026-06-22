module NetworkAccess
  module_function

  def guest_subnet_cidrs
    parse_cidrs(ENV.fetch('GUEST_SUBNET_CIDRS', ''))
  end

  def guest_subnets_configured?
    guest_subnet_cidrs.any?
  end

  def on_space?(ip_string)
    return false if ip_string.blank?
    return false unless guest_subnets_configured?

    ip = IPAddr.new(ip_string)
    guest_subnet_cidrs.any? { |cidr| cidr.include?(ip) }
  rescue IPAddr::InvalidAddressError
    false
  end

  def parse_cidrs(value)
    value.split(',').filter_map do |entry|
      IPAddr.new(entry.strip)
    end
  rescue IPAddr::InvalidAddressError
    []
  end
end
