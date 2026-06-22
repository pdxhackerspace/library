require 'test_helper'

class LoansOverdueNagJobTest < ActiveJob::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
    site_settings(:default).update!(overdue_nag_interval_days: 3)
  end

  test 'notifies overdue loans that have never been nagged' do
    loan = loans(:active)
    loan.update!(due_on: 1.day.ago.to_date, overdue_nagged_at: nil)

    with_mail_env do
      Loans::OverdueNagJob.perform_now
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not_nil loan.reload.overdue_nagged_at
  end

  test 'nags again after interval has passed' do
    loan = loans(:active)
    loan.update!(due_on: 10.days.ago.to_date, overdue_nagged_at: 4.days.ago)

    with_mail_env do
      Loans::OverdueNagJob.perform_now
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test 'skips overdue loans nagged within interval' do
    loan = loans(:active)
    loan.update!(due_on: 5.days.ago.to_date, overdue_nagged_at: 1.day.ago)

    with_mail_env do
      Loans::OverdueNagJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
  end

  test 'respects configurable nag interval from settings' do
    site_settings(:default).update!(overdue_nag_interval_days: 7)
    loan = loans(:active)
    loan.update!(due_on: 10.days.ago.to_date, overdue_nagged_at: 5.days.ago)

    with_mail_env do
      Loans::OverdueNagJob.perform_now
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
