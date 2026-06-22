require 'test_helper'

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'lists books' do
    get root_path
    assert_response :success
    assert_match 'Make Electronics', response.body
    assert_match 'Charles Platt', response.body
  end

  test 'admin creates book' do
    assert_difference 'Book.count', 1 do
      post books_path, params: {
        book: {
          title: 'New Book',
          author_names: ['Someone'],
          isbn_codes: ['9780201616224']
        }
      }
    end

    book = Book.order(:id).last
    assert_redirected_to book_path(book)
    assert_equal ['Someone'], book.authors.pluck(:name)
    assert_equal ['9780201616224'], book.isbn_codes
  end

  test 'member cannot create book' do
    delete logout_path
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }

    assert_no_difference 'Book.count' do
      post books_path, params: { book: { title: 'Blocked', author_names: ['Nope'] } }
    end
    assert_redirected_to root_path
  end

  test 'create book and add another returns to new book form' do
    assert_difference 'Book.count', 1 do
      post books_path, params: {
        add_another: 'Create book and add another',
        book: {
          title: 'Another Entry',
          author_names: ['Someone']
        }
      }
    end

    assert_redirected_to new_book_path
    assert_equal 'Book added to the library.', flash[:notice]
  end

  test 'checkout and return' do
    book = books(:pragmatic)
    site_settings(:default).update!(loan_period_days: 14)

    assert_difference 'Loan.count', 1 do
      post checkout_book_path(book)
    end
    assert_redirected_to book_path(book)
    assert_not book.reload.available?
    assert_equal Date.current + 14.days, book.active_loan.due_on

    post return_book_path(book)
    assert book.reload.available?
  end

  test 'new book form shows location presets' do
    get new_book_path
    assert_response :success
    assert_match 'Shelf A1', response.body
    assert_match 'Shelf B2', response.body
    assert_match 'book[location_id]', response.body
  end

  test 'admin assigns location when creating book' do
    location = locations(:shelf_a1)

    post books_path, params: {
      book: {
        title: 'Located Book',
        author_names: ['Someone'],
        location_id: location.id
      }
    }

    book = Book.order(:id).last
    assert_equal location, book.location
  end
end
