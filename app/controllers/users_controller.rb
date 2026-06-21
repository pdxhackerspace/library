class UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: :show

  def index
    @users = User.left_joins(:loans)
                 .select('users.*, COUNT(loans.id) AS loans_count')
                 .group('users.id')
                 .order(:name)
                 .to_a
  end

  def show
    @active_loans = @user.loans.active.includes(:book).recent
    @recent_loans = @user.loans.where.not(returned_at: nil).includes(:book).order(returned_at: :desc).limit(10)
  end

  private

  def set_user
    @user = User.find(params.expect(:id))
  end
end
