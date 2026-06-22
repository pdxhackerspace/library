require 'test_helper'

class LoansNotifyTest < ActiveSupport::TestCase
  setup do
    @loan = loans(:active)
    ActionMailer::Base.deliveries.clear
  end

  test 'borrowed sends email when smtp is configured' do
    with_mail_env do
      assert Loans::Notify.borrowed(@loan)
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal [@loan.user.email], ActionMailer::Base.deliveries.last.to
      assert_includes ActionMailer::Base.deliveries.last.subject, @loan.book.title
    end
  end

  test 'borrowed sends slack when configured' do
    @loan.user.update!(slack_uid: 'U999', slack_name: 'member')

    with_slack_env(token: 'xoxb-test') do
      stub_request(:post, SlackConfig.api_url)
        .to_return(status: 200, body: { ok: true }.to_json)

      assert Loans::Notify.borrowed(@loan)
      assert_requested :post, SlackConfig.api_url
    end
  end

  test 'due sends email when smtp is configured' do
    with_mail_env do
      assert Loans::Notify.due(@loan)
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_includes ActionMailer::Base.deliveries.last.subject, 'Due today'
    end
  end

  test 'overdue sends email when smtp is configured' do
    @loan.update!(due_on: 2.days.ago.to_date)

    with_mail_env do
      assert Loans::Notify.overdue(@loan)
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_includes ActionMailer::Base.deliveries.last.subject, 'Overdue'
    end
  end

  test 'returns false when no notification channels are configured' do
    assert_not Loans::Notify.borrowed(@loan)
    assert_empty ActionMailer::Base.deliveries
  end

  private

  def with_mail_env
    original = mail_env_keys.index_with { |key| ENV.fetch(key, nil) }
    mail_env_keys.each do |key|
      ENV[key] = key == 'SMTP_PORT' ? '587' : "test-#{key.downcase}"
    end
    yield
  ensure
    original.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  def with_slack_env(token:)
    original = ENV.fetch('SLACK_BOT_TOKEN', nil)
    ENV['SLACK_BOT_TOKEN'] = token
    yield
  ensure
    if original.nil?
      ENV.delete('SLACK_BOT_TOKEN')
    else
      ENV['SLACK_BOT_TOKEN'] = original
    end
  end

  def mail_env_keys
    %w[SMTP_ADDRESS SMTP_PORT SMTP_FROM]
  end
end
