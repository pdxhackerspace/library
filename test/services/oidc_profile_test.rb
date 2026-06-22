require 'test_helper'

class OidcProfileTest < ActiveSupport::TestCase
  test 'extracts slack info from raw_info' do
    auth = omniauth_auth(
      raw_info: { 'slack' => { 'uid' => 'U123', 'name' => 'alice' } }
    )

    assert_equal({ uid: 'U123', name: 'alice' }, OidcProfile.slack_info(auth))
  end

  test 'extracts slack info from id token payload' do
    auth = omniauth_auth(
      id_token_payload: { 'slack' => { 'uid' => 'U456', 'name' => 'bob' } }
    )

    assert_equal({ uid: 'U456', name: 'bob' }, OidcProfile.slack_info(auth))
  end

  test 'returns nil when slack uid is missing' do
    auth = omniauth_auth(raw_info: { 'slack' => { 'name' => 'alice' } })

    assert_nil OidcProfile.slack_info(auth)
  end

  test 'returns nil when slack block is absent' do
    auth = omniauth_auth

    assert_nil OidcProfile.slack_info(auth)
  end
end
