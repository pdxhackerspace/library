require 'test_helper'

class BooksWizardTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'new book form is a four step wizard starting at isbn' do
    get new_book_path
    assert_response :success
    assert_select 'form[data-book-wizard-editing-value=false][data-book-wizard-index-value="0"]'
    assert_select '[data-book-wizard-target=crumb]', 4
    assert_select '[data-book-wizard-target=step]', 4
    assert_select '[data-book-wizard-target=step]:not(.d-none) [data-book-form-target=scanButton]'
    assert_select '[data-book-wizard-target=saveActions].d-none'
  end

  test 'edit book form offers save on every step and isbn scanning' do
    get edit_book_path(books(:pragmatic))
    assert_response :success
    assert_select 'form[data-book-wizard-editing-value=true]'
    assert_select '[data-book-wizard-target=saveActions]:not(.d-none) input[value="Save & Exit"]'
    assert_select '[data-book-form-target=scanButton]'
  end

  test 'invalid book reopens the wizard on the step with the error' do
    post books_path, params: { book: { title: '', author_names: ['Someone'] } }
    assert_response :unprocessable_content
    assert_select 'form[data-book-wizard-index-value="1"][data-book-wizard-reached-value="3"]'

    post books_path, params: { book: { title: 'Fine', author_names: ['Someone'], copies_count: 0 } }
    assert_response :unprocessable_content
    assert_select 'form[data-book-wizard-index-value="3"]'
  end
end
