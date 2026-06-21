require 'test_helper'

class OidcDebugTest < ActiveSupport::TestCase
  test 'disabled by default' do
    with_debug(nil) do
      assert_not OidcDebug.enabled?
    end
  end

  test 'enabled when OIDC_DEBUG is true' do
    with_debug('true') do
      assert OidcDebug.enabled?
    end
  end

  test 'decodes jwt payload segment' do
    token = encode_jwt('is_admin' => true, 'sub' => 'abc')

    assert_equal({ 'is_admin' => true, 'sub' => 'abc' }, OidcDebug.decode_jwt_payload(token))
  end

  private

  def with_debug(value)
    original = ENV.fetch('OIDC_DEBUG', nil)
    value.nil? ? ENV.delete('OIDC_DEBUG') : ENV['OIDC_DEBUG'] = value
    yield
  ensure
    if original.nil?
      ENV.delete('OIDC_DEBUG')
    else
      ENV['OIDC_DEBUG'] = original
    end
  end

  def encode_jwt(payload)
    header = Base64.urlsafe_encode64({ alg: 'none', typ: 'JWT' }.to_json, padding: false)
    body = Base64.urlsafe_encode64(payload.to_json, padding: false)

    "#{header}.#{body}."
  end
end
