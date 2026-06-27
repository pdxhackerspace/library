require 'test_helper'

class BooksViewTrackingTest < ActionDispatch::IntegrationTest
  include GuestAccessTestHelper

  setup do
    @book = books(:pragmatic)
    @book.update!(view_count: 0, nfc_view_count: 0, borrow_count: 0)
  end

  test 'show increments view count' do
    with_guest_subnets('127.0.0.0/8') do
      get_from_ip book_path(@book), '127.0.0.1'

      assert_response :success
      assert_equal 1, @book.reload.view_count
      assert_equal 0, @book.nfc_view_count
    end
  end

  test 'show with nfc utm records counts and redirects to clean url' do
    with_guest_subnets('127.0.0.0/8') do
      get_from_ip book_path(@book, utm_source: 'nfc'), '127.0.0.1'

      assert_redirected_to book_path(@book)
      follow_redirect!

      assert_response :success
      assert_equal 1, @book.reload.view_count
      assert_equal 1, @book.nfc_view_count
      assert_not_includes response.request.url, 'utm_source=nfc'
    end
  end

  test 'nfc redirect does not double count view on follow up request' do
    with_guest_subnets('127.0.0.0/8') do
      get_from_ip book_path(@book, utm_source: 'nfc'), '127.0.0.1'
      follow_redirect!

      assert_equal 1, @book.reload.view_count
      assert_equal 1, @book.nfc_view_count
    end
  end

  test 'checkout increments borrow count' do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }

    assert_difference -> { @book.reload.borrow_count }, 1 do
      post checkout_book_path(@book)
    end

    assert_redirected_to book_path(@book)
  end
end
