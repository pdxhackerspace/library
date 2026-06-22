module Loans
  class OverdueNagJob < ApplicationJob
    queue_as :mailers

    def perform
      interval_days = SiteSetting.instance.overdue_nag_interval_days

      Loan.overdue.find_each do |loan|
        next unless loan.needs_overdue_nag?(interval_days: interval_days)
        next unless Loans::Notify.overdue(loan)

        loan.mark_overdue_nagged!
      end
    end
  end
end
