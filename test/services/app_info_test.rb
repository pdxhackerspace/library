require 'test_helper'

class AppInfoTest < ActiveSupport::TestCase
  setup do
    @original_app_version = ENV.fetch('APP_VERSION', nil)
    @original_github_repository = ENV.fetch('GITHUB_REPOSITORY', nil)
  end

  teardown do
    restore_env('APP_VERSION', @original_app_version)
    restore_env('GITHUB_REPOSITORY', @original_github_repository)
    AppInfo.instance_variable_set(:@version, nil)
    AppInfo.instance_variable_set(:@github_repo_url, nil)
  end

  test 'version reads VERSION file when APP_VERSION is unset' do
    ENV.delete('APP_VERSION')

    assert_equal Rails.root.join('VERSION').read.strip, AppInfo.version
  end

  test 'version prefers APP_VERSION environment variable' do
    ENV['APP_VERSION'] = '9.9.9'

    assert_equal '9.9.9', AppInfo.version
  end

  test 'github repo url uses GITHUB_REPOSITORY environment variable' do
    ENV['GITHUB_REPOSITORY'] = 'pdxhackerspace/library'

    assert_equal 'https://github.com/pdxhackerspace/library', AppInfo.github_repo_url
  end

  test 'parse_github_repository handles ssh remote' do
    assert_equal 'pdxhackerspace/library', AppInfo.parse_github_repository('git@github.com:pdxhackerspace/library.git')
  end

  private

  def restore_env(key, value)
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end
end
