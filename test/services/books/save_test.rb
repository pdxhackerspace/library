require 'test_helper'

module Books
  class SaveTest < ActiveSupport::TestCase
    test 'creates book with authors and isbns' do
      book = Book.new

      assert Books::Save.new(book, {
                               title: 'New Book',
                               author_names: ['Jane Doe', 'John Doe'],
                               published_on: '2020-01-15',
                               location_id: locations(:shelf_a1).id,
                               isbn_codes: ['9780201616224']
                             }).call

      book.reload
      assert_equal 'New Book', book.title
      assert_equal Date.new(2020, 1, 15), book.published_on
      assert_equal locations(:shelf_a1), book.location
      assert_equal ['Jane Doe', 'John Doe'], book.authors.pluck(:name)
      assert_equal ['9780201616224'], book.isbn_codes
      assert_equal 1, book.copies_count
    end

    test 'creates location from custom name' do
      book = Book.new

      assert_difference 'Location.count', 1 do
        assert Books::Save.new(book, {
                                 title: 'Custom Shelf Book',
                                 author_names: ['Jane Doe'],
                                 custom_location_name: 'Shelf C3'
                               }).call
      end

      book.reload
      assert_equal 'Shelf C3', book.location.name
    end

    test 'saves ebook url' do
      book = books(:pragmatic)

      assert Books::Save.new(book, {
                               title: book.title,
                               author_names: book.authors.pluck(:name),
                               ebook_url: 'https://example.com/ebook.pdf'
                             }).call

      assert_equal 'https://example.com/ebook.pdf', book.reload.ebook_url
    end

    test 'saves copies count' do
      book = Book.new

      assert Books::Save.new(book, {
                               title: 'Multiple Copies',
                               author_names: ['Jane Doe'],
                               copies_count: 4
                             }).call

      assert_equal 4, book.reload.copies_count
    end

    test 'replaces authors and isbns on update' do
      book = books(:pragmatic)

      assert Books::Save.new(book, {
                               title: book.title,
                               author_names: ['Solo Author'],
                               subject_names: [],
                               isbn_codes: %w[9780201616224 9780132350884]
                             }).call

      book.reload
      assert_equal ['Solo Author'], book.authors.pluck(:name)
      assert_equal 2, book.isbns.count
    end

    test 'creates book with metadata fields and pending covers' do
      stub_request(:get, 'https://example.com/cover.jpg')
        .to_return(status: 200, body: 'jpeg-bytes', headers: { 'Content-Type' => 'image/jpeg' })

      book = Book.new

      assert Books::Save.new(book, {
                               title: 'Metadata Book',
                               author_names: ['Author One'],
                               description: 'A description',
                               publisher: 'Publisher',
                               page_count: 200,
                               language: 'en',
                               subject_names: %w[Electronics Programming],
                               pending_cover_urls: ['https://example.com/cover.jpg']
                             }).call

      book.reload
      assert_equal 'A description', book.description
      assert_equal %w[Electronics Programming], book.subjects.pluck(:name)
      assert book.covers_attached?
    end
  end
end
