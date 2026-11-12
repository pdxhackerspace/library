require 'test_helper'

module Api
  module V1
    class CatalogControllerTest < ActionDispatch::IntegrationTest
      AUTH = { 'Authorization' => 'Bearer lib_test-indexer-token' }.freeze

      test 'requires an API key' do
        get api_v1_catalog_path

        assert_response :unauthorized
        assert_match 'Bearer', response.headers['WWW-Authenticate']
      end

      test 'rejects an unknown key' do
        get api_v1_catalog_path, headers: { 'Authorization' => 'Bearer lib_nope' }

        assert_response :unauthorized
      end

      test 'session login alone is not enough' do
        sign_in_local(users(:admin))
        get api_v1_catalog_path

        assert_response :unauthorized
      end

      test 'returns the catalog as JSON Lines' do
        get api_v1_catalog_path, headers: AUTH

        assert_response :success
        assert_equal 'application/jsonl', response.media_type
        lines = response.body.lines
        assert_equal Book.count, lines.size
        assert(lines.all? { |line| JSON.parse(line)['title'].present? })
        assert api_keys(:indexer).reload.last_used_at
      end

      test 'supports since and rejects a bad timestamp' do
        books(:electronics).update!(updated_at: 2.days.ago)

        get api_v1_catalog_path, params: { since: 1.day.ago.iso8601 }, headers: AUTH
        assert_response :success
        assert_equal Book.count - 1, response.body.lines.size

        get api_v1_catalog_path, params: { since: 'yesterday' }, headers: AUTH
        assert_response :bad_request
      end

      test 'returns 304 when the catalog has not changed' do
        get api_v1_catalog_path, headers: AUTH
        etag = response.headers['ETag']

        get api_v1_catalog_path, headers: AUTH.merge('If-None-Match' => etag)

        assert_response :not_modified
      end
    end
  end
end
