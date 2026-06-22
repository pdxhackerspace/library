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
end
