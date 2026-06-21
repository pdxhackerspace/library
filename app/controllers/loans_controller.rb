class LoansController < ApplicationController
  before_action :require_login

  def index
    @loans = Loan.includes(:book, :user).recent.limit(100)
  end

  def show
    @loan = Loan.includes(:book, :user).find(params.expect(:id))
  end
end
