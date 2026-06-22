require 'test_helper'

class LoansDueReminderJobTest < ActiveJob::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test 'notifies loans due today that have not been notified' do
    loan = loans(:active)
    loan.update!(due_on: Date.current, due_notified_on: nil)

    with_mail_env do
      Loans::DueReminderJob.perform_now
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal Date.current, loan.reload.due_notified_on
  end

  test 'skips loans already notified for due date' do
    loan = loans(:active)
    loan.update!(due_on: Date.current, due_notified_on: Date.current)

    with_mail_env do
      Loans::DueReminderJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
  end

  test 'skips loans not due today' do
    loans(:active).update!(due_on: Date.current + 1.day, due_notified_on: nil)

    with_mail_env do
      Loans::DueReminderJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
  end

  private

  def with_mail_env
    original = %w[SMTP_ADDRESS SMTP_PORT SMTP_FROM].index_with { |key| ENV.fetch(key, nil) }
    ENV['SMTP_ADDRESS'] = 'smtp.example.com'
    ENV['SMTP_PORT'] = '587'
    ENV['SMTP_FROM'] = 'library@example.com'
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
end
