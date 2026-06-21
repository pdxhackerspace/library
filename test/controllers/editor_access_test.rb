require 'test_helper'

class EditorAccessTest < ActionDispatch::IntegrationTest
  test 'editor can create and edit books' do
    sign_in_as(users(:editor))

    assert_difference 'Book.count', 1 do
      post books_path, params: {
        book: {
          title: 'Editor Added Book',
          author_names: ['Someone']
        }
      }
    end

    book = Book.order(:id).last
    assert_redirected_to book_path(book)

    patch book_path(book), params: {
      book: {
        title: 'Editor Updated Book',
        author_names: ['Someone']
      }
    }
    assert_redirected_to book_path(book)
    assert_equal 'Editor Updated Book', book.reload.title
  end

  test 'editor sees add book control' do
    sign_in_as(users(:editor))

    get root_path
    assert_response :success
    assert_match 'Add book', response.body
  end

  test 'editor cannot access settings' do
    sign_in_as(users(:editor))

    get settings_path
    assert_redirected_to root_path
    assert_equal 'Admin access required.', flash[:alert]
  end

  test 'editor cannot access users' do
    sign_in_as(users(:editor))

    get users_path
    assert_redirected_to root_path
    assert_equal 'Admin access required.', flash[:alert]
  end

  test 'editor search omits users' do
    sign_in_as(users(:editor))

    get search_path
    assert_response :success
    assert_match 'Search across books, authors, subjects, and publishers.', response.body
    assert_no_match 'and users', response.body

    get search_path, params: { q: 'admin@example.com' }
    assert_no_match 'h-section-label">Users', response.body
  end

  test 'member cannot manage books' do
    sign_in_local(users(:member))

    get new_book_path
    assert_redirected_to root_path

    assert_no_difference 'Book.count' do
      post books_path, params: { book: { title: 'Blocked', author_names: ['Nope'] } }
    end
  end
end
