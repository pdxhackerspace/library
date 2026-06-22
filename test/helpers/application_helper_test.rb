require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'book_cover_tag renders placeholder when no cover attached' do
    book = books(:pragmatic)

    html = book_cover_tag(book, size: :hero)

    assert_includes html, 'book-cover--hero'
    assert_includes html, 'book-cover--placeholder'
    assert_includes html, 'bi-book'
    assert_includes html, 'book-cover__initial'
    assert_includes html, '>T<'
  end

  test 'book_cover_tag applies shelf size class' do
    html = book_cover_tag(books(:pragmatic), size: :shelf)

    assert_includes html, 'book-cover--shelf'
  end

  test 'book_status_dot reflects availability' do
    available = book_status_dot(books(:pragmatic))
    on_loan = book_status_dot(books(:electronics))

    assert_includes available, 'status-dot status-success'
    assert_includes on_loan, 'status-dot status-warning'
  end
end
