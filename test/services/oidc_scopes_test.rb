require 'test_helper'

class OidcScopesTest < ActiveSupport::TestCase
  test 'admin when is_admin scope is granted' do
    auth = omniauth_auth(scopes: %w[openid email profile is_admin])

    assert OidcScopes.admin?(auth)
    assert_not OidcScopes.editor?(auth)
  end

  test 'editor when is_editor scope is granted' do
    auth = omniauth_auth(scopes: %w[openid email profile is_editor])

    assert_not OidcScopes.admin?(auth)
    assert OidcScopes.editor?(auth)
  end

  test 'admin from id token scope claim' do
    auth = omniauth_auth(
      scopes: %w[openid email profile],
      id_token_payload: { 'scope' => 'openid email profile is_admin is_editor' }
    )

    assert OidcScopes.admin?(auth)
    assert OidcScopes.editor?(auth)
  end

  test 'roles require granted scopes not userinfo claims' do
    auth = omniauth_auth(
      scopes: %w[openid email profile],
      raw_info: { 'is_admin' => true, 'is_editor' => true }
    )

    assert_not OidcScopes.admin?(auth)
    assert_not OidcScopes.editor?(auth)
  end

  test 'custom admin scope name' do
    with_scope_env('OIDC_ADMIN_SCOPES' => 'library-admin') do
      auth = omniauth_auth(scopes: %w[openid email profile library-admin])

      assert OidcScopes.admin?(auth)
    end
  end
end
