class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :user

  validates :checked_out_at, presence: true
  validates :due_on, presence: true
  validate :book_must_be_available_on_checkout, on: :create

  scope :active, -> { where(returned_at: nil) }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :recent, -> { order(checked_out_at: :desc) }

  def active?
    returned_at.nil?
  end

  def overdue?
    active? && due_on < Date.current
  end

  def return!(at: Time.current)
    update!(returned_at: at)
  end

  private

  def book_must_be_available_on_checkout
    return if book.nil?
    return if book.active_loan.nil? || book.active_loan == self

    errors.add(:book, 'is already on loan')
  end
end
