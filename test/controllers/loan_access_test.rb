require 'test_helper'

class LoanAccessTest < ActionDispatch::IntegrationTest
  test 'admin sees loans link in navbar' do
    sign_in_local(users(:admin))

    get root_path

    assert_response :success
    assert_select 'a[href=?]', loans_path, text: 'Loans'
  end

  test 'member does not see loans link in navbar' do
    sign_in_local(users(:member))

    get root_path

    assert_response :success
    assert_select 'a[href=?]', loans_path, count: 0
  end

  test 'editor does not see loans link in navbar' do
    sign_in_as(users(:editor))

    get root_path

    assert_response :success
    assert_select 'a[href=?]', loans_path, count: 0
  end

  test 'member books index hides loan summary count' do
    sign_in_local(users(:member))

    get books_path

    assert_response :success
    assert_no_match %r{text-warning">\d+</span> on loan}, response.body
  end

  test 'admin books index shows loan summary' do
    sign_in_local(users(:admin))

    get books_path

    assert_response :success
    assert_match 'on loan', response.body
  end
end
