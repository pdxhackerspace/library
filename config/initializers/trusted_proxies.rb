proxies = ENV.fetch('TRUSTED_PROXIES', '').split(',').map(&:strip).compact_blank

if proxies.any?
  Rails.application.config.action_dispatch.trusted_proxies = (
    ActionDispatch::RemoteIp::TRUSTED_PROXIES + proxies.filter_map do |entry|
      IPAddr.new(entry)
    end
  ).uniq
end
