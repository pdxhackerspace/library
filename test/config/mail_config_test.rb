require 'test_helper'

class MailConfigTest < ActiveSupport::TestCase
  setup do
    @keys = %w[SMTP_ADDRESS SMTP_PORT SMTP_FROM SMTP_USERNAME SMTP_PASSWORD SMTP_DOMAIN]
    @original = @keys.index_with { |key| ENV.fetch(key, nil) }
  end

  teardown do
    @original.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  test 'configured when address and from are set' do
    ENV['SMTP_ADDRESS'] = 'smtp.example.com'
    ENV['SMTP_FROM'] = 'library@example.com'

    assert MailConfig.configured?
  end

  test 'not configured without from address' do
    ENV['SMTP_ADDRESS'] = 'smtp.example.com'
    ENV.delete('SMTP_FROM')

    assert_not MailConfig.configured?
  end
end
