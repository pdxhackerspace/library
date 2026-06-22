module Loans
  class DueReminderJob < ApplicationJob
    queue_as :mailers

    def perform
      Loan.due_today_unnotified.find_each do |loan|
        next unless Loans::Notify.due(loan)

        loan.mark_due_notified!
      end
    end
  end
end
