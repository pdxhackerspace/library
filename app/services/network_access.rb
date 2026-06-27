module NetworkAccess
  module_function

  def guest_subnet_cidrs
    guest_subnet_entries.pluck(:cidr)
  end

  def guest_subnet_labels
    guest_subnet_entries.pluck(:label)
  end

  def guest_subnet_entries
    parse_subnet_entries(ENV.fetch('GUEST_SUBNET_CIDRS', ''))
  end

  def guest_subnets_configured?
    guest_subnet_cidrs.any?
  end

  def on_space?(ip_string)
    evaluate_on_space(ip_string)[:on_space]
  end

  def evaluate_on_space(ip_string)
    return { on_space: false, reason: 'blank_ip', matching_cidr: nil } if ip_string.blank?

    unless guest_subnets_configured?
      return { on_space: false, reason: 'no_guest_subnets_configured', matching_cidr: nil }
    end

    ip = IPAddr.new(ip_string)
    matching_entry = guest_subnet_entries.find { |entry| entry[:cidr].include?(ip) }

    if matching_entry
      { on_space: true, reason: 'ip_in_guest_subnet', matching_cidr: matching_entry[:label] }
    else
      { on_space: false, reason: 'ip_not_in_guest_subnets', matching_cidr: nil }
    end
  rescue IPAddr::InvalidAddressError
    { on_space: false, reason: 'invalid_ip', matching_cidr: nil }
  end

  def parse_subnet_entries(value)
    value.split(',').filter_map do |entry|
      label = entry.strip
      next if label.blank?

      { label: label, cidr: IPAddr.new(label) }
    end
  rescue IPAddr::InvalidAddressError
    []
  end

  def parse_cidrs(value)
    parse_subnet_entries(value).pluck(:cidr)
  end
end
