require 'test_helper'

class SentryConfigTest < ActiveSupport::TestCase
  setup do
    @original_dsn = ENV.fetch('SENTRY_DSN', nil)
    @original_environment = ENV.fetch('SENTRY_ENVIRONMENT', nil)
    @original_traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', nil)
    @original_app_version = ENV.fetch('APP_VERSION', nil)
  end

  teardown do
    restore_env('SENTRY_DSN', @original_dsn)
    restore_env('SENTRY_ENVIRONMENT', @original_environment)
    restore_env('SENTRY_TRACES_SAMPLE_RATE', @original_traces_sample_rate)
    restore_env('APP_VERSION', @original_app_version)
  end

  test 'not configured without dsn' do
    ENV.delete('SENTRY_DSN')

    assert_not SentryConfig.configured?
  end

  test 'not configured in test even with dsn' do
    ENV['SENTRY_DSN'] = 'https://examplePublicKey@o0.ingest.sentry.io/0'

    assert_not SentryConfig.configured?
  end

  test 'environment defaults to rails env' do
    ENV.delete('SENTRY_ENVIRONMENT')

    assert_equal Rails.env, SentryConfig.environment
  end

  test 'traces sample rate defaults to zero' do
    ENV.delete('SENTRY_TRACES_SAMPLE_RATE')

    assert_in_delta 0.0, SentryConfig.traces_sample_rate
  end

  test 'traces sample rate parses configured value' do
    ENV['SENTRY_TRACES_SAMPLE_RATE'] = '0.25'

    assert_in_delta 0.25, SentryConfig.traces_sample_rate
  end

  test 'release prefers app version env var' do
    ENV['APP_VERSION'] = '1.2.3'

    assert_equal '1.2.3', SentryConfig.release
  end

  test 'release falls back to version file' do
    ENV.delete('APP_VERSION')

    assert_equal Rails.root.join('VERSION').read.strip, SentryConfig.release
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
