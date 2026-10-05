require 'test_helper'

class BooksControllerMetadataTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'lookup metadata enqueues job' do
    assert_enqueued_with(job: Books::MetadataLookupJob) do
      post lookup_metadata_books_path,
           params: { isbn: '9780201616224', lookup_token: 'token-123' },
           headers: { 'Accept' => 'application/json' }
    end

    assert_response :accepted
    assert_equal 'queued', response.parsed_body['status']
  end

  test 'edit lookup metadata enqueues job for empty fields' do
    book = books(:pragmatic)

    assert_enqueued_with(job: Books::MetadataLookupJob) do
      post lookup_metadata_book_path(book),
           params: { isbn: '9780201616224', lookup_token: 'token-456' },
           headers: { 'Accept' => 'application/json' }
    end

    assert_response :accepted
  end
end
