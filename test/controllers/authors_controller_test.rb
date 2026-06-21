require 'test_helper'

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'lists authors' do
    get authors_path
    assert_response :success
    assert_match 'Charles Platt', response.body
    assert_match '>3</span> authors', response.body
    assert_no_match(/\{\d+=>/, response.body)
  end

  test 'shows author books' do
    get author_path(authors(:david_thomas))
    assert_response :success
    assert_match 'The Pragmatic Programmer', response.body
  end
end
