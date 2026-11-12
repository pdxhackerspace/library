require 'test_helper'

class ApiKeyTest < ActiveSupport::TestCase
  test 'generate exposes the plain token once and stores only a digest' do
    key = ApiKey.generate(name: 'Indexer')
    key.save!

    assert key.token.start_with?('lib_')
    assert_equal ApiKey.digest(key.token), key.token_digest
    assert_equal key.token.first(10), key.token_prefix
    assert_nil ApiKey.find(key.id).token
  end

  test 'authenticate finds a key by token' do
    assert_equal api_keys(:indexer), ApiKey.authenticate('lib_test-indexer-token')
    assert_nil ApiKey.authenticate('lib_wrong')
    assert_nil ApiKey.authenticate('')
  end

  test 'requires a name' do
    assert_not ApiKey.generate(name: '').valid?
  end

  test 'record_use! updates last_used_at at most once a minute' do
    key = api_keys(:indexer)
    key.record_use!
    first = key.reload.last_used_at
    assert first

    key.record_use!
    assert_equal first, key.reload.last_used_at
  end
end
