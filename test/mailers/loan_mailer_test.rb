require 'test_helper'

class LoanMailerTest < ActionMailer::TestCase
  setup do
    @loan = loans(:active)
  end

  test 'borrowed email includes book title and due date' do
    mail = LoanMailer.borrowed(@loan)

    assert_equal [@loan.user.email], mail.to
    assert_includes mail.subject, @loan.book.title
    assert_includes mail.body.encoded, @loan.due_on.to_fs(:long)
  end

  test 'due email mentions due today' do
    mail = LoanMailer.due(@loan)

    assert_includes mail.subject, 'Due today'
    assert_includes mail.body.encoded, @loan.book.title
  end

  test 'overdue email includes days overdue' do
    @loan.update!(due_on: 3.days.ago.to_date)
    mail = LoanMailer.overdue(@loan)

    assert_includes mail.subject, 'Overdue'
    assert_includes mail.body.encoded, '3 days'
  end
end
