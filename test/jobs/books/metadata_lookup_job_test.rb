require 'test_helper'

module Books
  class MetadataLookupJobTest < ActiveJob::TestCase
    setup do
      stub_request(:get, %r{https://openlibrary.org/api/books})
        .to_return(
          status: 200,
          body: file_fixture('metadata/open_library_pragmatic.json').read,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    test 'broadcast renders metadata lookup turbo stream' do
      assert_nothing_raised do
        Books::MetadataLookupJob.perform_now(
          lookup_token: 'test-token',
          isbn: '9780201616224',
          only_empty: false
        )
      end
    end

    test 'broadcasts not found status when lookup misses' do
      stub_request(:get, %r{https://openlibrary.org/api/books})
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r{https://www.googleapis.com/books/v1/volumes})
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      assert_nothing_raised do
        Books::MetadataLookupJob.perform_now(
          lookup_token: 'missing-token',
          isbn: '9780201616224',
          only_empty: false
        )
      end
    end

    test 'annotates persisted book with metadata source when filling empty fields' do
      stub_request(:get, %r{https://covers.openlibrary.org/})
        .to_return(status: 200, body: 'jpeg-bytes', headers: { 'Content-Type' => 'image/jpeg' })

      book = books(:electronics)
      book.update!(description: nil, metadata_source: nil, source_url: nil, metadata_fetched_at: nil)

      Books::MetadataLookupJob.perform_now(
        lookup_token: 'edit-token',
        isbn: '9780201616224',
        book_id: book.id,
        only_empty: true
      )

      book.reload
      assert_equal 'open_library', book.metadata_source
      assert_match(/openlibrary.org/, book.source_url)
      assert book.metadata_fetched_at.present?
    end
  end
end
