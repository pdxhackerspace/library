require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include GuestAccessTestHelper

  test 'shows catalog sections for on subnet guest' do
    with_guest_subnets('127.0.0.0/8') do
      get root_path, env: { 'REMOTE_ADDR' => '127.0.0.1' }

      assert_response :success
      assert_match 'Recently added', response.body
      assert_match 'Popular', response.body
      assert_match 'Discover', response.body
    end
  end

  test 'shows all books link for logged in user' do
    sign_in_as(users(:admin))

    get root_path

    assert_response :success
    assert_match 'All books', response.body
  end
end
