require 'test_helper'

class BooksControllerShowTest < ActionDispatch::IntegrationTest
  include GuestAccessTestHelper

  test 'show page uses cover-first layout for logged in user' do
    sign_in_local(users(:admin))

    get book_path(books(:pragmatic))

    assert_response :success
    assert_match 'book-detail', response.body
    assert_match 'book-cover--hero', response.body
    assert_match 'book-detail__meta', response.body
    assert_match 'data-controller="book-cover"', response.body
    assert_match 'The Pragmatic Programmer', response.body
    assert_match 'Check out', response.body
    assert_no_match '<dl class="row', response.body
  end

  test 'show page uses same cover-first layout for on subnet guest' do
    with_guest_subnets('192.168.1.0/24') do
      get_from_ip book_path(books(:pragmatic)), '192.168.1.50'

      assert_response :success
      assert_match 'book-detail', response.body
      assert_match 'book-cover--hero', response.body
      assert_match 'Sign in to check out', response.body
      assert_no_match '<dl class="row', response.body
    end
  end

  test 'home shelf marks on loan books with status dot' do
    with_guest_subnets('127.0.0.0/8') do
      get root_path, env: { 'REMOTE_ADDR' => '127.0.0.1' }

      assert_response :success
      assert_match 'book-shelf', response.body
      assert_match 'status-dot status-warning', response.body
    end
  end
end
