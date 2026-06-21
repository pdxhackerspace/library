require 'test_helper'

class OidcClaimsTest < ActiveSupport::TestCase
  test 'admin from raw_info claim' do
    auth = omniauth_auth(raw_info: { 'is_admin' => true })

    assert OidcClaims.admin?(auth)
  end

  test 'admin from id token payload when userinfo omits claim' do
    auth = omniauth_auth(
      raw_info: { 'email' => 'oidc@example.com' },
      id_token_payload: { 'is_admin' => true, 'is_editor' => false }
    )

    assert OidcClaims.admin?(auth)
    assert_not OidcClaims.editor?(auth)
  end

  test 'admin from id token even when userinfo claim is false' do
    auth = omniauth_auth(
      raw_info: { 'is_admin' => false },
      id_token_payload: { 'is_admin' => true }
    )

    assert OidcClaims.admin?(auth)
  end

  test 'admin from alternate claim name' do
    with_claim_env('OIDC_ADMIN_CLAIMS' => 'admin') do
      auth = omniauth_auth(raw_info: { 'admin' => 'true' })

      assert OidcClaims.admin?(auth)
    end
  end

  test 'admin from configured group membership' do
    with_claim_env('OIDC_ADMIN_GROUPS' => 'library-admins') do
      auth = omniauth_auth(raw_info: { 'groups' => %w[members library-admins] })

      assert OidcClaims.admin?(auth)
    end
  end

  test 'string true claim is treated as admin' do
    auth = omniauth_auth(raw_info: { 'is_admin' => 'True' })

    assert OidcClaims.admin?(auth)
  end

  private

  def with_claim_env(overrides)
    original = overrides.keys.index_with { |key| ENV.fetch(key, nil) }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  def omniauth_auth(raw_info: {}, id_token_payload: nil)
    info = { 'email' => 'oidc@example.com', 'name' => 'OIDC User' }
    credentials = Struct.new(:id_token).new(id_token_payload ? encode_jwt(id_token_payload) : nil)
    extra = Struct.new(:raw_info).new(raw_info)

    Struct.new(:provider, :uid, :info, :extra, :credentials).new('oidc', '123', info, extra, credentials)
  end

  def encode_jwt(payload)
    header = Base64.urlsafe_encode64({ alg: 'none', typ: 'JWT' }.to_json, padding: false)
    body = Base64.urlsafe_encode64(payload.to_json, padding: false)

    "#{header}.#{body}."
  end
end
