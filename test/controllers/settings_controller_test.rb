require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }
  end

  test 'admin views settings' do
    get settings_path
    assert_response :success
    assert_match 'Site name', response.body
    assert_match 'Loan period', response.body
    assert_match 'Shelf A1', response.body
  end

  test 'admin updates site settings' do
    patch settings_path, params: {
      site_setting: {
        site_name: 'Hackerspace Books',
        loan_period_days: 14
      }
    }

    assert_redirected_to settings_path
    assert_equal 'Hackerspace Books', SiteSetting.instance.site_name
    assert_equal 14, SiteSetting.instance.loan_period_days
  end

  test 'admin downloads books csv' do
    get books_csv_settings_path

    assert_response :success
    assert_includes response.media_type, 'text/csv'
    assert_match(/^id,title,subtitle,authors,subjects,location,/, response.body)
    assert_includes response.body, books(:pragmatic).title
  end

  test 'member cannot download books csv' do
    delete logout_path
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }

    get books_csv_settings_path
    assert_redirected_to root_path
  end

  test 'member cannot access settings' do
    delete logout_path
    post login_path, params: { email: users(:member).email, password: 'test-password-123' }

    get settings_path
    assert_redirected_to root_path
  end
end
