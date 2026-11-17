require 'test_helper'

class MetricsControllerTest < ActionDispatch::IntegrationTest
  include MetricsTestHelper

  test 'is a 404 when no token is configured' do
    with_metrics(token: nil) do
      get metrics_path, headers: { 'Authorization' => "Bearer #{TOKEN}" }

      assert_response :not_found
    end
  end

  test 'requires a token' do
    with_metrics do
      get metrics_path

      assert_response :unauthorized
      assert_match 'Bearer', response.headers['WWW-Authenticate']
    end
  end

  test 'rejects a wrong token' do
    with_metrics do
      get metrics_path, headers: { 'Authorization' => 'Bearer nope' }

      assert_response :unauthorized
    end
  end

  test 'rejects a library API key and a signed-in session' do
    with_metrics do
      sign_in_local(users(:admin))
      get metrics_path, headers: { 'Authorization' => 'Bearer lib_test-indexer-token' }

      assert_response :unauthorized
    end
  end

  test 'serves Prometheus text with a valid token' do
    with_metrics do
      get metrics_path, headers: { 'Authorization' => "Bearer #{TOKEN}" }

      assert_response :success
      assert_equal Metrics::Exposition::CONTENT_TYPE, response.headers['Content-Type']
      assert_includes response.body, '# TYPE library_books gauge'
    end
  end

  test 'does not count its own scrapes as requests' do
    with_metrics do
      get metrics_path, headers: { 'Authorization' => "Bearer #{TOKEN}" }

      assert_empty Metrics::RequestRecorder.read
    end
  end
end
