module Loans
  class Notify
    def self.borrowed(loan)
      new(loan).borrowed
    end

    def self.due(loan)
      new(loan).due
    end

    def self.overdue(loan)
      new(loan).overdue
    end

    def initialize(loan)
      @loan = loan
      @user = loan.user
      @book = loan.book
    end

    def borrowed
      deliver(
        mailer: LoanMailer.borrowed(@loan),
        slack_text: borrowed_slack_text
      )
    end

    def due
      deliver(
        mailer: LoanMailer.due(@loan),
        slack_text: due_slack_text
      )
    end

    def overdue
      deliver(
        mailer: LoanMailer.overdue(@loan),
        slack_text: overdue_slack_text
      )
    end

    private

    attr_reader :loan, :user, :book

    def deliver(mailer:, slack_text:)
      email_sent = deliver_email(mailer)
      slack_sent = Notifications::SlackMessenger.call(user: user, text: slack_text)

      email_sent || slack_sent
    end

    def deliver_email(mailer)
      return false unless MailConfig.configured?
      return false if user.email.blank?

      mailer.deliver_now
      true
    rescue StandardError
      false
    end

    def borrowed_slack_text
      <<~TEXT.squish
        You checked out "#{book.title}" from #{site_name}.
        Due #{loan.due_on.to_fs(:long)}.
      TEXT
    end

    def due_slack_text
      <<~TEXT.squish
        "#{book.title}" is due today at #{site_name}.
        Please return it when you can.
      TEXT
    end

    def overdue_slack_text
      days = (Date.current - loan.due_on).to_i
      <<~TEXT.squish
        "#{book.title}" is #{days} #{'day'.pluralize(days)} overdue at #{site_name}.
        Please return it as soon as you can.
      TEXT
    end

    def site_name
      SiteSetting.instance.site_name
    end
  end
end
