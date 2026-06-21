class Author < ApplicationRecord
  include InventoryCounts

  has_many :book_authors, dependent: :destroy
  has_many :books, through: :book_authors

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  scope :ordered, -> { order(:name) }

  private

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, ' ')
  end
end
