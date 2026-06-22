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

  def get_from_ip(path, ip, proxy: '127.0.0.1')
    get path, env: { 'REMOTE_ADDR' => proxy, 'HTTP_X_FORWARDED_FOR' => ip }
  end
end
