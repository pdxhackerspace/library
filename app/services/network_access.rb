module NetworkAccess
  module_function

  def guest_subnet_cidrs
    parse_cidrs(ENV.fetch('GUEST_SUBNET_CIDRS', ''))
  end

  def guest_subnets_configured?
    guest_subnet_cidrs.any?
  end

  def on_space?(ip_string)
    evaluate_on_space(ip_string)[:on_space]
  end

  def evaluate_on_space(ip_string)
    if ip_string.blank?
      return { on_space: false, reason: 'blank_ip', matching_cidr: nil }
    end

    unless guest_subnets_configured?
      return { on_space: false, reason: 'no_guest_subnets_configured', matching_cidr: nil }
    end

    ip = IPAddr.new(ip_string)
    matching_cidr = guest_subnet_cidrs.find { |cidr| cidr.include?(ip) }

    if matching_cidr
      { on_space: true, reason: 'ip_in_guest_subnet', matching_cidr: matching_cidr.to_s }
    else
      { on_space: false, reason: 'ip_not_in_guest_subnets', matching_cidr: nil }
    end
  rescue IPAddr::InvalidAddressError
    { on_space: false, reason: 'invalid_ip', matching_cidr: nil }
  end

  def parse_cidrs(value)
    value.split(',').filter_map do |entry|
      IPAddr.new(entry.strip)
    end
  rescue IPAddr::InvalidAddressError
    []
  end
end
