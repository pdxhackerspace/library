class Location < ApplicationRecord
  include InventoryCounts

  has_many :books, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  scope :ordered, -> { order(:position, :name) }
  scope :alphabetical, -> { order(:name) }

  def self.find_or_create_by_name!(name)
    normalized = name.to_s.strip.gsub(/\s+/, ' ')
    where('LOWER(name) = ?', normalized.downcase).first_or_create!(name: normalized)
  end

  private

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, ' ')
  end
end
