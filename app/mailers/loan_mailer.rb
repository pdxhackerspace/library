class LoanMailer < ApplicationMailer
  def borrowed(loan)
    @loan = loan
    @book = loan.book
    @user = loan.user
    @site_name = SiteSetting.instance.site_name

    mail(to: @user.email, subject: borrowed_subject)
  end

  def due(loan)
    @loan = loan
    @book = loan.book
    @user = loan.user
    @site_name = SiteSetting.instance.site_name

    mail(to: @user.email, subject: due_subject)
  end

  def overdue(loan)
    @loan = loan
    @book = loan.book
    @user = loan.user
    @site_name = SiteSetting.instance.site_name
    @days_overdue = (Date.current - loan.due_on).to_i

    mail(to: @user.email, subject: overdue_subject)
  end

  private

  def borrowed_subject
    "Checked out: #{@book.title}"
  end

  def due_subject
    "Due today: #{@book.title}"
  end

  def overdue_subject
    "Overdue: #{@book.title}"
  end
end
