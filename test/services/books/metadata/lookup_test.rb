require 'test_helper'

module Books
  module Metadata
    class LookupTest < ActiveSupport::TestCase
      test 'falls back to google books when open library misses' do
        stub_request(:get, %r{https://openlibrary.org/api/books})
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        ENV['GOOGLE_BOOKS_API_KEY'] = 'test-key'
        stub_request(:get, %r{https://www.googleapis.com/books/v1/volumes})
          .to_return(
            status: 200,
            body: file_fixture('metadata/google_books_pragmatic.json').read,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Books::Metadata::Lookup.call('9780201616224')
        assert_equal 'google_books', result.source
      ensure
        ENV.delete('GOOGLE_BOOKS_API_KEY')
      end
    end
  end
end
