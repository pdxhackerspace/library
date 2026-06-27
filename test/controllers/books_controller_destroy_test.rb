require 'test_helper'

class BooksControllerDestroyTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'admin deletes book that is not on loan' do
    book = books(:pragmatic)
    title = book.title

    assert_difference 'Book.count', -1 do
      delete book_path(book)
    end

    assert_redirected_to books_path
    assert_response :see_other
    assert_equal "\"#{title}\" removed from the library.", flash[:notice]

    follow_redirect!
    assert_response :success
    assert_not Book.exists?(book.id)
    assert_select "a[href='#{book_path(book)}']", count: 0
  end

  test 'admin deletes book that is on loan' do
    book = books(:electronics)
    title = book.title

    assert book.on_loan?

    assert_difference 'Book.count', -1 do
      delete book_path(book)
    end

    assert_redirected_to books_path
    assert_response :see_other
    assert_equal "\"#{title}\" removed from the library.", flash[:notice]
  end

  test 'show page delete action is in kebab menu' do
    book = books(:pragmatic)

    get book_path(book)

    assert_response :success
    assert_select "form[action='#{book_path(book)}'] input[name='_method'][value='delete']", 1
  end

  test 'edit form delete button is not nested inside main form' do
    book = books(:pragmatic)

    get edit_book_path(book)

    assert_response :success
    assert_select 'form.card.border-secondary-subtle form', count: 0
    assert_select "form[action='#{book_path(book)}'] input[name='_method'][value='delete']", 1
  end
end
