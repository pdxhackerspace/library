class Subject < ApplicationRecord
  include InventoryCounts

  has_many :book_subjects, dependent: :destroy
  has_many :books, through: :book_subjects

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  scope :ordered, -> { order(:name) }
  scope :with_books, -> { joins(:books).distinct }

  private

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, ' ')
  end
end
