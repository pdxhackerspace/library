require 'test_helper'

class NetworkAccessDebugTest < ActiveSupport::TestCase
  test 'disabled by default' do
    with_debug(nil) do
      assert_not NetworkAccessDebug.enabled?
    end
  end

  test 'enabled when NETWORK_ACCESS_DEBUG is true' do
    with_debug('true') do
      assert NetworkAccessDebug.enabled?
    end
  end

  test 'payload includes decision proxy headers and configured networks' do
    with_network_debug_payload do |payload|
      assert payload[:decision][:on_space]
      assert_equal '192.168.1.0/24', payload[:decision][:matching_cidr]
      assert_equal '192.168.1.50', payload[:resolved_client_ip]
      assert_equal 'remote_ip', payload[:client_ip_source]
      assert_equal '10.0.0.1', payload[:direct_connection_ip]
      assert_equal '10.0.0.1', payload[:proxy][:remote_addr]
      assert_equal '192.168.1.50', payload[:proxy][:x_forwarded_for]
      assert_equal ['192.168.1.0/24'], payload[:guest_subnet_cidrs]
      assert_equal '10.0.0.0/8', payload[:trusted_proxies_env]
      assert payload[:trusted_proxies].any?
    end
  end

  private

  def with_network_debug_payload # rubocop:disable Metrics/MethodLength
    ENV['GUEST_SUBNET_CIDRS'] = '192.168.1.0/24'
    ENV['TRUSTED_PROXIES'] = '10.0.0.0/8'
    TrustedProxies.reset!

    request = ActionDispatch::Request.new(
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/',
      'QUERY_STRING' => '',
      'REMOTE_ADDR' => '10.0.0.1',
      'HTTP_X_FORWARDED_FOR' => '192.168.1.50',
      'HTTP_X_REAL_IP' => '192.168.1.50',
      'action_dispatch.remote_ip' => '10.0.0.1'
    )
    evaluation = NetworkAccess.evaluate_on_space('192.168.1.50')

    yield NetworkAccessDebug.payload(request, evaluation)
  ensure
    ENV.delete('GUEST_SUBNET_CIDRS')
    ENV.delete('TRUSTED_PROXIES')
    TrustedProxies.reset!
  end

  def with_debug(value)
    original = ENV.fetch('NETWORK_ACCESS_DEBUG', nil)
    value.nil? ? ENV.delete('NETWORK_ACCESS_DEBUG') : ENV['NETWORK_ACCESS_DEBUG'] = value
    yield
  ensure
    if original.nil?
      ENV.delete('NETWORK_ACCESS_DEBUG')
    else
      ENV['NETWORK_ACCESS_DEBUG'] = original
    end
  end
end
