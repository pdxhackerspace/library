module SignInHelper
  def sign_in_as(user)
    post test_sign_in_path, params: { user_id: user.id }
  end

  def sign_in_local(user, password: 'test-password-123')
    post login_path, params: { email: user.email, password: password }
  end
end
