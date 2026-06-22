require 'test_helper'

class UserSlackTest < ActiveSupport::TestCase
  test 'from_omniauth stores slack info from auth server' do
    user = User.from_omniauth(
      omniauth_auth(
        scopes: %w[openid email profile slack],
        slack: { 'uid' => 'U123', 'name' => 'alice' }
      )
    )

    assert_equal 'U123', user.slack_uid
    assert_equal 'alice', user.slack_name
    assert user.slack_linked?
  end

  test 'from_omniauth updates slack info on each login' do
    create_oidc_user(uid: 'slack-user', email: 'slack@example.com', admin: false, editor: false)

    User.from_omniauth(
      omniauth_auth(
        uid: 'slack-user',
        email: 'slack@example.com',
        slack: { 'uid' => 'U111', 'name' => 'first' }
      )
    )
    user = User.find_by(uid: 'slack-user')
    assert_equal 'U111', user.slack_uid

    User.from_omniauth(
      omniauth_auth(
        uid: 'slack-user',
        email: 'slack@example.com',
        slack: { 'uid' => 'U222', 'name' => 'second' }
      )
    )
    user.reload
    assert_equal 'U222', user.slack_uid
    assert_equal 'second', user.slack_name
  end

  test 'from_omniauth clears slack info when scope data is absent' do
    user = create_oidc_user(uid: 'slack-clear', email: 'clear@example.com', admin: false, editor: false)
    user.update!(slack_uid: 'UOLD', slack_name: 'old')

    User.from_omniauth(
      omniauth_auth(uid: 'slack-clear', email: 'clear@example.com')
    )

    user.reload
    assert_nil user.slack_uid
    assert_nil user.slack_name
  end

  private

  def create_oidc_user(uid:, email:, admin:, editor:)
    User.create!(
      provider: 'oidc',
      uid: uid,
      email: email,
      name: 'OIDC User',
      admin: admin,
      editor: editor
    )
  end
end
