require 'test_helper'

module Settings
  class ApiKeysControllerTest < ActionDispatch::IntegrationTest
    test 'admin creates a key and sees the token once' do
      sign_in_local(users(:admin))

      assert_difference 'ApiKey.count', 1 do
        post settings_api_keys_path, params: { api_key: { name: 'Open WebUI' } }
      end

      assert_response :success
      key = ApiKey.order(:id).last
      token = response.body[/lib_[1-9A-HJ-NP-Za-km-z]{32}/]
      assert_equal 'Open WebUI', key.name
      assert_equal users(:admin), key.created_by
      assert_equal key, ApiKey.authenticate(token)
      assert_equal 'no-store', response.headers['Cache-Control']

      get settings_path
      assert_match 'Open WebUI', response.body
      assert_no_match token, response.body
    end

    test 'blank name is rejected' do
      sign_in_local(users(:admin))

      assert_no_difference 'ApiKey.count' do
        post settings_api_keys_path, params: { api_key: { name: ' ' } }
      end

      assert_redirected_to settings_path(anchor: 'api-keys')
    end

    test 'admin revokes a key' do
      sign_in_local(users(:admin))

      assert_difference 'ApiKey.count', -1 do
        delete settings_api_key_path(api_keys(:indexer))
      end

      assert_nil ApiKey.authenticate('lib_test-indexer-token')
    end

    test 'non-admins cannot manage keys' do
      sign_in_local(users(:member))

      assert_no_difference 'ApiKey.count' do
        post settings_api_keys_path, params: { api_key: { name: 'Sneaky' } }
      end
      assert_no_difference 'ApiKey.count' do
        delete settings_api_key_path(api_keys(:indexer))
      end
    end
  end
end
