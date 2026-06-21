require 'test_helper'

class LoansControllerTest < ActionDispatch::IntegrationTest
  test 'admin can view loans index' do
    sign_in_local(users(:admin))

    get loans_path

    assert_response :success
    assert_match 'Recent loans', response.body
  end

  test 'member cannot view loans index' do
    sign_in_local(users(:member))

    get loans_path

    assert_redirected_to root_path
    assert_equal 'Admin access required.', flash[:alert]
  end

  test 'editor cannot view loans index' do
    sign_in_as(users(:editor))

    get loans_path

    assert_redirected_to root_path
    assert_equal 'Admin access required.', flash[:alert]
  end
end
