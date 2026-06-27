require 'test_helper'

class MatomoTrackingTest < ActionDispatch::IntegrationTest
  include GuestAccessTestHelper

  setup do
    site_settings(:default).update!(matomo_url: nil, matomo_site_id: nil)
  end

  test 'layout omits matomo when not configured' do
    with_guest_subnets('127.0.0.0/8') do
      get_from_ip root_path, '127.0.0.1'

      assert_response :success
      assert_no_match 'matomo.js', response.body
      assert_no_match '_paq', response.body
    end
  end

  test 'layout includes matomo when configured' do
    site_settings(:default).update!(
      matomo_url: 'https://matomo.example.com',
      matomo_site_id: 3
    )

    with_guest_subnets('127.0.0.0/8') do
      get_from_ip root_path, '127.0.0.1'

      assert_response :success
      assert_match 'matomo.example.com', response.body
      assert_match 'matomo.js', response.body
      assert_match "['setSiteId', 3]", response.body
      assert_match 'turbo:load', response.body
    end
  end
end
