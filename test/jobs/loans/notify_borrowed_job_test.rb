require 'test_helper'

class LoansNotifyBorrowedJobTest < ActiveJob::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test 'notifies borrower for active loan' do
    loan = loans(:active)

    with_mail_env do
      perform_enqueued_jobs do
        Loans::NotifyBorrowedJob.perform_later(loan.id)
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test 'does nothing for returned loan' do
    loan = loans(:active)
    loan.return!

    with_mail_env do
      Loans::NotifyBorrowedJob.perform_now(loan.id)
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
