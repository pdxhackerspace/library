require 'test_helper'

class NetworkAccessTest < ActiveSupport::TestCase
  setup do
    @original = ENV.fetch('GUEST_SUBNET_CIDRS', nil)
  end

  teardown do
    if @original
      ENV['GUEST_SUBNET_CIDRS'] = @original
    else
      ENV.delete('GUEST_SUBNET_CIDRS')
    end
  end

  test 'matches ipv4 cidr' do
    ENV['GUEST_SUBNET_CIDRS'] = '192.168.1.0/24'

    assert NetworkAccess.on_space?('192.168.1.50')
    assert_not NetworkAccess.on_space?('10.0.0.1')
  end

  test 'returns false when subnets are not configured' do
    ENV.delete('GUEST_SUBNET_CIDRS')

    assert_not NetworkAccess.on_space?('127.0.0.1')
  end

  test 'returns false for invalid ip' do
    ENV['GUEST_SUBNET_CIDRS'] = '192.168.1.0/24'

    assert_not NetworkAccess.on_space?('not-an-ip')
  end

  test 'parses comma separated cidrs' do
    ENV['GUEST_SUBNET_CIDRS'] = '10.0.0.0/8,192.168.1.0/24'

    assert NetworkAccess.on_space?('10.1.2.3')
    assert NetworkAccess.on_space?('192.168.1.2')
    assert_not NetworkAccess.on_space?('172.16.0.1')
  end

  test 'evaluate_on_space reports matching cidr and reason' do
    ENV['GUEST_SUBNET_CIDRS'] = '192.168.1.0/24'

    result = NetworkAccess.evaluate_on_space('192.168.1.50')

    assert result[:on_space]
    assert_equal 'ip_in_guest_subnet', result[:reason]
    assert_equal '192.168.1.0/24', result[:matching_cidr]
  end

  test 'evaluate_on_space reports when ip is outside guest subnets' do
    ENV['GUEST_SUBNET_CIDRS'] = '192.168.1.0/24'

    result = NetworkAccess.evaluate_on_space('10.0.0.1')

    assert_not result[:on_space]
    assert_equal 'ip_not_in_guest_subnets', result[:reason]
    assert_nil result[:matching_cidr]
  end
end
