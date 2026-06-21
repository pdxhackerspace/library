require 'test_helper'

module GlobalSearch
  class QueryTest < ActiveSupport::TestCase
    test 'excludes users when include_users is false' do
      results = Query.call('admin@example.com', include_users: false)

      assert_empty results.users
    end

    test 'includes users when include_users is true' do
      results = Query.call('admin@example.com', include_users: true)

      assert results.users.any?
    end
  end
end
