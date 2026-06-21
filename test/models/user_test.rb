require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'normalizes email' do
    user = User.new(name: 'Test', email: '  Admin@Example.COM ', password: 'test-password-123')
    user.valid?
    assert_equal 'admin@example.com', user.email
  end

  test 'local account has no provider' do
    assert users(:admin).local_account?
  end

  test 'local member is not admin or editor' do
    user = users(:member)

    assert user.local_account?
    assert_not user.admin?
    assert_not user.editor?
    assert_not user.can_manage_books?
  end

  test 'bootstrap local admin is always admin' do
    user = users(:admin)
    user.update_columns(admin: false) # rubocop:disable Rails/SkipsModelValidations -- simulate stale role data

    assert user.reload.admin?
    assert user.can_manage_books?
  end

  test 'editor can manage books but is not admin' do
    user = users(:editor)

    assert user.editor?
    assert user.can_manage_books?
    assert_not user.admin?
  end

  test 'from_omniauth sets admin and editor from claims' do
    user = User.from_omniauth(omniauth_auth(is_admin: true, is_editor: true))

    assert user.admin?
    assert user.editor?
  end

  test 'from_omniauth clears roles when claims are false' do
    user = create_oidc_user(uid: '456', email: 'former-admin@example.com', admin: true, editor: true)

    User.from_omniauth(omniauth_auth(is_admin: false, is_editor: false, uid: '456', email: 'former-admin@example.com'))

    user.reload
    assert_not user.admin?
    assert_not user.editor?
  end

  test 'from_omniauth updates roles on each login' do
    create_oidc_user(uid: '789', email: 'changing@example.com', admin: true, editor: false)

    User.from_omniauth(omniauth_auth(is_admin: false, is_editor: true, uid: '789', email: 'changing@example.com'))
    user = User.find_by(uid: '789')
    assert_not user.admin?
    assert user.editor?

    User.from_omniauth(omniauth_auth(is_admin: true, is_editor: false, uid: '789', email: 'changing@example.com'))
    user.reload
    assert user.admin?
    assert_not user.editor?
  end

  test 'update cannot change admin or editor' do
    user = create_oidc_user(uid: 'mass-assign', email: 'mass@example.com', admin: false, editor: false)

    user.update(admin: true, editor: true)
    user.reload

    assert_not user.read_attribute(:admin)
    assert_not user.read_attribute(:editor)
  end

  test 'sync_roles_from_omniauth can change roles' do
    user = create_oidc_user(uid: 'sync', email: 'sync@example.com', admin: false, editor: false)

    User.sync_roles_from_omniauth!(
      user,
      omniauth_auth(is_admin: true, is_editor: true, uid: 'sync', email: 'sync@example.com')
    )

    assert user.reload.admin?
    assert user.editor?
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

  def omniauth_auth(is_admin: false, is_editor: false, uid: '123', email: 'oidc@example.com')
    info = Struct.new(:email, :name, :is_admin, :is_editor).new(email, 'OIDC User', nil, nil)
    extra = Struct.new(:raw_info).new({ 'is_admin' => is_admin, 'is_editor' => is_editor })

    Struct.new(:provider, :uid, :info, :extra).new('oidc', uid, info, extra)
  end
end
