require 'test_helper'

class BooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

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

  test 'admin deletes book that is not on loan' do
    book = books(:pragmatic)

    assert_difference 'Book.count', -1 do
      delete book_path(book)
    end

    assert_redirected_to books_path
    assert_equal 'Book removed from the library.', flash[:notice]
  end

  test 'admin cannot delete book that is on loan' do
    book = books(:electronics)

    assert_no_difference 'Book.count' do
      delete book_path(book)
    end

    assert_redirected_to book_path(book)
    assert_equal 'Return the book before deleting it.', flash[:alert]
  end

  test 'edit form delete button is not nested inside main form' do
    book = books(:pragmatic)

    get edit_book_path(book)

    assert_response :success
    assert_select 'form.card.border-secondary-subtle form', count: 0
    assert_select "form[action='#{book_path(book)}'] input[name='_method'][value='delete']", 1
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

  test 'scan isbn accepts photo upload and returns isbn list' do
    uploaded = fixture_file_upload('scan.jpg', 'image/jpeg')

    post scan_isbn_books_path, params: { photo: uploaded }, headers: { 'Accept' => 'application/json' }

    assert_response :success
    assert response.parsed_body.key?('isbns')
    assert_kind_of Array, response.parsed_body['isbns']
  end

  test 'scan isbn requires photo' do
    post scan_isbn_books_path, as: :json
    assert_response :unprocessable_entity
  end

  test 'lookup metadata enqueues job' do
    assert_enqueued_with(job: Books::MetadataLookupJob) do
      post lookup_metadata_books_path,
           params: { isbn: '9780201616224', lookup_token: 'token-123' },
           headers: { 'Accept' => 'application/json' }
    end

    assert_response :accepted
    assert_equal 'queued', response.parsed_body['status']
  end

  test 'edit lookup metadata enqueues job for empty fields' do
    book = books(:pragmatic)

    assert_enqueued_with(job: Books::MetadataLookupJob) do
      post lookup_metadata_book_path(book),
           params: { isbn: '9780201616224', lookup_token: 'token-456' },
           headers: { 'Accept' => 'application/json' }
    end

    assert_response :accepted
  end
end
