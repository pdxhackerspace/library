require 'test_helper'

class LayoutTest < ActionDispatch::IntegrationTest
  test 'footer shows version and github link when logged in' do
    post login_path, params: { email: users(:admin).email, password: 'test-password-123' }

    get root_path

    assert_response :success
    assert_match(/v#{Regexp.escape(AppInfo.version)}/, response.body)
    assert_match AppInfo.github_repo_url, response.body if AppInfo.github_repo_url.present?
  end
end
