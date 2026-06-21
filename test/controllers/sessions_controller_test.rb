require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'shows local sign-in only when OIDC is not configured' do
    get login_path

    assert_response :success
    assert_select 'input[type=email]'
    assert_select 'input[type=submit][value="Sign in"]'
    assert_select 'button', text: /Sign in with SSO/, count: 0
    assert_select 'details', count: 0
  end

  test 'shows SSO first and hides local sign-in behind details when OIDC is configured' do
    with_oidc_env do
      get login_path

      assert_response :success
      assert_select 'button', text: 'Sign in with SSO'
      assert_select 'details summary', text: 'Sign in with email and password'
      assert_select 'details input[type=email]'
    end
  end

  test 'signs in local admin' do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test 'rejects bad password' do
    post login_path, params: { email: users(:admin).email, password: 'wrong' }
    assert_response :unprocessable_entity
  end
end
