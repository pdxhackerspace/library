require 'test_helper'

class RequestClientIpTest < ActiveSupport::TestCase
  setup do
    TrustedProxies.reset!
  end

  test 'uses x forwarded for when upstream proxy is trusted' do
    with_trusted_proxies('172.225.80.225') do
      request = build_request(
        remote_addr: '172.225.80.225',
        x_forwarded_for: '192.168.1.50'
      )

      resolution = RequestClientIp.resolve(request)

      assert_equal '192.168.1.50', resolution.ip
      assert_equal 'remote_ip', resolution.source
      assert_equal '172.225.80.225', resolution.direct_ip
    end
  end

  test 'uses x real ip when upstream proxy is trusted' do
    with_trusted_proxies('172.225.80.225') do
      request = build_request(
        remote_addr: '172.225.80.225',
        x_real_ip: '192.168.1.50'
      )

      resolution = RequestClientIp.resolve(request)

      assert_equal '192.168.1.50', resolution.ip
      assert_equal 'x_real_ip', resolution.source
    end
  end

  test 'uses leftmost x forwarded for when trust forwarded headers is enabled' do
    ENV['TRUST_FORWARDED_HEADERS'] = 'true'
    TrustedProxies.reset!

    request = build_request(
      remote_addr: '172.225.80.225',
      x_forwarded_for: '192.168.1.50, 172.225.80.225'
    )

    resolution = RequestClientIp.resolve(request)

    assert_equal '192.168.1.50', resolution.ip
    assert_equal 'x_forwarded_for', resolution.source
  ensure
    ENV.delete('TRUST_FORWARDED_HEADERS')
    TrustedProxies.reset!
  end

  test 'falls back to direct connection when upstream is not trusted' do
    ENV.delete('TRUSTED_PROXIES')
    ENV.delete('TRUST_FORWARDED_HEADERS')
    TrustedProxies.reset!

    request = build_request(
      remote_addr: '172.225.80.225',
      x_forwarded_for: '192.168.1.50'
    )

    resolution = RequestClientIp.resolve(request)

    assert_equal '172.225.80.225', resolution.ip
    assert_equal 'remote_addr', resolution.source
  ensure
    TrustedProxies.reset!
  end

  test 'reads configured client ip header' do
    with_trusted_proxies('172.225.80.225') do
      ENV['CLIENT_IP_HEADER'] = 'CF-Connecting-IP'

      request = build_request(
        remote_addr: '172.225.80.225',
        headers: { 'HTTP_CF_CONNECTING_IP' => '192.168.1.50' }
      )

      resolution = RequestClientIp.resolve(request)

      assert_equal '192.168.1.50', resolution.ip
      assert_equal 'client_ip_header', resolution.source
    end
  ensure
    ENV.delete('CLIENT_IP_HEADER')
  end

  private

  def with_trusted_proxies(*entries)
    original = ENV.fetch('TRUSTED_PROXIES', nil)
    ENV['TRUSTED_PROXIES'] = entries.join(',')
    TrustedProxies.reset!
    yield
  ensure
    if original
      ENV['TRUSTED_PROXIES'] = original
    else
      ENV.delete('TRUSTED_PROXIES')
    end
    TrustedProxies.reset!
  end

  def build_request(remote_addr:, x_forwarded_for: nil, x_real_ip: nil, headers: {})
    env = {
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/',
      'QUERY_STRING' => '',
      'REMOTE_ADDR' => remote_addr
    }
    env['HTTP_X_FORWARDED_FOR'] = x_forwarded_for if x_forwarded_for
    env['HTTP_X_REAL_IP'] = x_real_ip if x_real_ip
    env.merge!(headers)

    ActionDispatch::Request.new(env)
  end
end
