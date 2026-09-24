require 'test_helper'

class AdminBootstrapTest < ActiveSupport::TestCase
  setup do
    @original_admin_email = ENV.fetch('ADMIN_EMAIL', nil)
    @original_admin_password = ENV.fetch('ADMIN_PASSWORD', nil)
    @original_admin_name = ENV.fetch('ADMIN_NAME', nil)
  end

  teardown do
    restore_env('ADMIN_EMAIL', @original_admin_email)
    restore_env('ADMIN_PASSWORD', @original_admin_password)
    restore_env('ADMIN_NAME', @original_admin_name)
  end

  test 'creates admin user with bcrypt password digest' do
    ENV['ADMIN_EMAIL'] = 'bootstrap-new@example.com'
    ENV['ADMIN_PASSWORD'] = 'secure-password-123'
    ENV['ADMIN_NAME'] = 'Bootstrap Admin'

    assert_difference -> { User.where(email: 'bootstrap-new@example.com').count }, 1 do
      AdminBootstrap.call
    end

    user = User.find_by!(email: 'bootstrap-new@example.com')
    assert user.admin?
    assert_equal 'Bootstrap Admin', user.name
    assert user.password_digest.present?
    assert BCrypt::Password.new(user.password_digest).is_password?('secure-password-123')
  end

  test 'does not overwrite password for existing admin user' do
    user = users(:admin)
    original_digest = user.password_digest

    ENV['ADMIN_EMAIL'] = user.email
    ENV['ADMIN_PASSWORD'] = 'different-password-456'
    ENV['ADMIN_NAME'] = 'Updated Admin Name'

    AdminBootstrap.call

    user.reload
    assert_equal 'Updated Admin Name', user.name
    assert user.admin?
    assert_equal original_digest, user.password_digest
    assert BCrypt::Password.new(user.password_digest).is_password?('test-password-123')
  end

  test 'no-ops when credentials are missing' do
    ENV.delete('ADMIN_EMAIL')
    ENV.delete('ADMIN_PASSWORD')

    assert_no_difference -> { User.count } do
      AdminBootstrap.call
    end
  end

  private

  def restore_env(key, value)
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end
end
