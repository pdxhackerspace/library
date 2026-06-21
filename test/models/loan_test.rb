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
end
