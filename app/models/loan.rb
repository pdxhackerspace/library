class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :user

  validates :checked_out_at, presence: true
  validates :due_on, presence: true
  validate :book_must_be_available_on_checkout, on: :create

  after_create_commit :notify_borrowed

  scope :active, -> { where(returned_at: nil) }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :recent, -> { order(checked_out_at: :desc) }
  scope :due_today, -> { active.where(due_on: Date.current) }
  scope :due_today_unnotified, -> { due_today.where(due_notified_on: nil) }
  scope :overdue, -> { active.where(due_on: ...Date.current) }

  def active?
    returned_at.nil?
  end

  def overdue?
    active? && due_on < Date.current
  end

  def return!(at: Time.current)
    update!(returned_at: at)
  end

  def due_today?
    active? && due_on == Date.current
  end

  def needs_overdue_nag?(interval_days: SiteSetting.instance.overdue_nag_interval_days)
    return false unless overdue?

    overdue_nagged_at.nil? || overdue_nagged_at <= interval_days.days.ago
  end

  def mark_due_notified!
    update!(due_notified_on: Date.current)
  end

  def mark_overdue_nagged!
    update!(overdue_nagged_at: Time.current)
  end

  private

  def notify_borrowed
    Loans::NotifyBorrowedJob.perform_later(id)
  end

  def book_must_be_available_on_checkout
    return if book.nil?
    return if book.active_loan.nil? || book.active_loan == self

    errors.add(:book, 'is already on loan')
  end
end
