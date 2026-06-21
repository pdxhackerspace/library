require 'test_helper'

module Books
  module Metadata
    class GoogleBooksClientTest < ActiveSupport::TestCase
      setup do
        ENV['GOOGLE_BOOKS_API_KEY'] = 'test-key'
        stub_request(:get, %r{https://www.googleapis.com/books/v1/volumes})
          .to_return(
            status: 200,
            body: file_fixture('metadata/google_books_pragmatic.json').read,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      teardown do
        ENV.delete('GOOGLE_BOOKS_API_KEY')
      end

      test 'parses google books metadata' do
        result = Books::Metadata::GoogleBooksClient.call('9780201616224')

        assert_equal 'The Pragmatic Programmer', result.title
        assert_includes result.author_names, 'Andrew Hunt'
        assert_equal 'google_books', result.source
        assert result.cover_urls.any?
      end
    end
  end
end
