require 'test_helper'

class InventoryCountsTest < ActiveSupport::TestCase
  test 'with_inventory_counts sums copies for authors' do
    book = books(:pragmatic)

    assert Books::Save.new(book, {
                             title: book.title,
                             author_names: book.authors.pluck(:name),
                             subject_names: [],
                             isbn_codes: book.isbn_codes,
                             copies_count: 3
                           }).call

    author = Author.with_inventory_counts.find(authors(:david_thomas).id)

    assert_equal 1, author.books_count
    assert_equal 3, author.copies_count
  end
end
