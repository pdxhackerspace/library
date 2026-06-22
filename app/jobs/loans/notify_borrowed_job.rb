module Loans
  class NotifyBorrowedJob < ApplicationJob
    queue_as :mailers

    def perform(loan_id)
      loan = Loan.find_by(id: loan_id)
      return if loan.nil? || !loan.active?

      Loans::Notify.borrowed(loan)
    end
  end
end
