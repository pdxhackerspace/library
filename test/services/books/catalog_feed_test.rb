require 'test_helper'

module Books
  class CatalogFeedTest < ActiveSupport::TestCase
    URL_OPTIONS = { host: 'library.example.com', port: nil, protocol: 'https://' }.freeze

    def records(**)
      CatalogFeed.new(url_options: URL_OPTIONS, **).call.lines.map { |line| JSON.parse(line) }
    end

    test 'emits one JSON object per book with static catalog data' do
      book = books(:pragmatic)
      book.update!(description: 'Classic advice.', created_at: Time.zone.parse('2025-03-04 10:00'))
      record = records.find { |row| row['id'] == book.id }

      assert_equal Book.count, records.size
      assert_equal "https://library.example.com/books/#{book.id}", record['url']
      assert_equal 'The Pragmatic Programmer', record['title']
      assert_equal ['David Thomas', 'Andrew Hunt'], record['authors']
      assert_equal ['9780201616224'], record['isbns']
      assert_equal 'Shelf B2', record['location']
      assert_equal '1999-10-30', record['published_on']
      assert_equal '2025-03-04', record['added_on']
      assert record['added_at'].start_with?('2025-03-04')
      assert_includes record['text'], 'Title: The Pragmatic Programmer'
      assert_includes record['text'], 'Authors: David Thomas, Andrew Hunt'
      assert_includes record['text'], 'Added to library: 2025-03-04'
      assert_includes record['text'], 'Description: Classic advice.'
    end

    test 'leaves out loan and usage data' do
      record = records.first

      %w[available on_loan loans borrow_count view_count nfc_view_count due_on borrower].each do |key|
        assert_not record.key?(key), "feed should not include #{key}"
      end
    end

    test 'since returns only books updated at or after the time' do
      books(:electronics).update!(updated_at: 2.days.ago)
      books(:pragmatic).update!(updated_at: 1.hour.ago)

      ids = records(since: 1.day.ago).pluck('id')

      assert_equal [books(:pragmatic).id], ids
    end

    test 'changing authors bumps the book updated_at' do
      book = books(:electronics)
      book.update!(updated_at: 2.days.ago)

      book.book_authors.first.update!(position: 3)

      assert book.reload.updated_at > 1.minute.ago
    end
  end
end
