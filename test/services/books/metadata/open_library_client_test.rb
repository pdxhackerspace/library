require 'test_helper'

module Books
  module Metadata
    class OpenLibraryClientTest < ActiveSupport::TestCase
      setup do
        stub_request(:get, %r{https://openlibrary.org/api/books})
          .to_return(
            status: 200,
            body: file_fixture('metadata/open_library_pragmatic.json').read,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      test 'parses open library metadata' do
        result = Books::Metadata::OpenLibraryClient.call('9780201616224')

        assert_equal 'The Pragmatic Programmer', result.title
        assert_includes result.author_names, 'David Thomas'
        assert_equal Date.new(1999, 1, 1), result.published_on
        assert_equal 'Addison-Wesley', result.publisher
        assert_equal 'open_library', result.source
        assert result.cover_urls.any?
      end

      test 'extracts publisher and subject names from hash payloads' do
        stub_request(:get, %r{https://openlibrary.org/api/books})
          .to_return(
            status: 200,
            body: {
              'ISBN:9780440539810' => {
                'title' => 'Illuminatus!',
                'publishers' => [{ 'name' => 'Dell Pub. Co.' }],
                'subjects' => [
                  { 'name' => 'American Science fiction',
                    'url' => 'https://openlibrary.org/subjects/american_science_fiction' },
                  { 'name' => 'conspiracy', 'url' => 'https://openlibrary.org/subjects/conspiracy' }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Books::Metadata::OpenLibraryClient.call('9780440539810')

        assert_equal 'Dell Pub. Co.', result.publisher
        assert_equal ['American Science fiction', 'conspiracy'], result.subjects
      end
    end
  end
end
