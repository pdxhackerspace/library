require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'shows login page' do
    get login_path
    assert_response :success
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
