require 'test_helper'

class BooksCoverUploadTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'edit form offers cover upload' do
    get edit_book_path(books(:pragmatic))

    assert_response :success
    assert_select 'form[enctype="multipart/form-data"]'
    assert_select 'input[type=file][name="book[cover_uploads][]"][multiple]'
  end

  test 'editor uploads a cover photo' do
    book = books(:pragmatic)

    patch book_path(book), params: {
      book: {
        title: book.title,
        author_names: book.authors.pluck(:name),
        cover_uploads: [fixture_file_upload('cover.png', 'image/png')]
      }
    }

    assert_redirected_to book_path(book)
    assert book.reload.covers_attached?
  end
end
