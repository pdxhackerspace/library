require 'test_helper'

class LoanTest < ActiveSupport::TestCase
  test 'overdue when active and past due date' do
    loan = loans(:active)
    loan.update!(due_on: 1.day.ago.to_date)
    assert loan.overdue?
  end

  test 'return marks returned_at' do
    loan = loans(:active)
    loan.return!
    assert_not loan.active?
    assert_not_nil loan.returned_at
  end

  test 'cannot checkout book that is already on loan' do
    book = books(:electronics)
    loan = Loan.new(
      book: book,
      user: users(:admin),
      checked_out_at: Time.current,
      due_on: 30.days.from_now.to_date
    )
    assert_not loan.valid?
  end

  test 'needs overdue nag when never nagged' do
    loan = loans(:active)
    loan.update!(due_on: 1.day.ago.to_date, overdue_nagged_at: nil)

    assert loan.needs_overdue_nag?
  end

  test 'needs overdue nag when last nag is older than interval' do
    site_settings(:default).update!(overdue_nag_interval_days: 3)
    loan = loans(:active)
    loan.update!(due_on: 10.days.ago.to_date, overdue_nagged_at: 4.days.ago)

    assert loan.needs_overdue_nag?
  end

  test 'does not need overdue nag within interval' do
    site_settings(:default).update!(overdue_nag_interval_days: 3)
    loan = loans(:active)
    loan.update!(due_on: 10.days.ago.to_date, overdue_nagged_at: 1.day.ago)

    assert_not loan.needs_overdue_nag?
  end

  test 'due today scope finds active loans due today' do
    loan = loans(:active)
    loan.update!(due_on: Date.current)

    assert_includes Loan.due_today, loan
  end
end
