require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'search page requires a query to show results' do
    get search_path
    assert_response :success
    assert_match 'Search across books', response.body
  end

  test 'search finds books and authors' do
    get search_path, params: { q: 'Pragmatic' }

    assert_response :success
    assert_match 'The Pragmatic Programmer', response.body
    assert_match 'David Thomas', response.body
  end

  test 'member search omits users from scope text' do
    delete logout_path
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }

    get search_path
    assert_response :success
    assert_match 'Search across books, authors, subjects, and publishers.', response.body
    assert_no_match(/users/i, response.body)
  end

  test 'member search does not return users' do
    delete logout_path
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }

    get search_path, params: { q: 'admin@example.com' }

    assert_response :success
    assert_no_match 'h-section-label">Users', response.body
  end
end
