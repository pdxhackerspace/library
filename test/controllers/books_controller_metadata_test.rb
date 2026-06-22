require 'test_helper'

class BooksControllerMetadataTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'scan isbn accepts photo upload and returns isbn list' do
    uploaded = fixture_file_upload('scan.jpg', 'image/jpeg')

    post scan_isbn_books_path, params: { photo: uploaded }, headers: { 'Accept' => 'application/json' }

    assert_response :success
    assert response.parsed_body.key?('isbns')
    assert_kind_of Array, response.parsed_body['isbns']
  end

  test 'scan isbn requires photo' do
    post scan_isbn_books_path, as: :json
    assert_response :unprocessable_entity
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
