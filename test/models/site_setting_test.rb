require 'test_helper'

class SiteSettingTest < ActiveSupport::TestCase
  test 'instance returns singleton row' do
    setting = SiteSetting.instance
    assert_equal site_settings(:default).site_name, setting.site_name
  end

  test 'validates loan period is positive' do
    setting = SiteSetting.instance
    setting.loan_period_days = 0

    assert_not setting.valid?
  end

  test 'validates overdue nag interval is positive' do
    setting = SiteSetting.instance
    setting.overdue_nag_interval_days = 0

    assert_not setting.valid?
  end

  test 'matomo enabled when url and site id are set' do
    setting = SiteSetting.instance
    setting.matomo_url = 'https://matomo.example.com'
    setting.matomo_site_id = 1

    assert setting.matomo_enabled?
    assert_equal 'https://matomo.example.com', setting.matomo_tracker_base_url
  end

  test 'matomo disabled when url is blank' do
    setting = SiteSetting.instance
    setting.matomo_url = nil
    setting.matomo_site_id = 1

    assert_not setting.matomo_enabled?
  end

  test 'requires site id when matomo url is set' do
    setting = SiteSetting.instance
    setting.matomo_url = 'https://matomo.example.com'
    setting.matomo_site_id = nil

    assert_not setting.valid?
    assert_includes setting.errors[:matomo_site_id], 'is required when Matomo URL is set'
  end

  test 'rejects invalid matomo url format' do
    setting = SiteSetting.instance
    setting.matomo_url = 'not-a-url'
    setting.matomo_site_id = 1

    assert_not setting.valid?
    assert_includes setting.errors[:matomo_url], 'is invalid'
  end
end
