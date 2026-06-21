require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'admin lists users with count' do
    get users_path
    assert_response :success
    assert_match '>3</span> total', response.body
    assert_no_match(/\{\d+=>/, response.body)
  end

  test 'member cannot list users' do
    delete logout_path
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }

    get users_path
    assert_redirected_to root_path
  end
end
