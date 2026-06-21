class BookSubject < ApplicationRecord
  belongs_to :book
  belongs_to :subject

  validates :subject_id, uniqueness: { scope: :book_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
