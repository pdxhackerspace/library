class Location < ApplicationRecord
  include InventoryCounts

  # Books are detached in #detach_books (not dependent: :nullify) so their updated_at moves too.
  has_many :books, dependent: nil

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name
  after_update_commit :touch_books, if: :saved_change_to_name?
  before_destroy :detach_books

  scope :ordered, -> { order(:position, :name) }
  scope :alphabetical, -> { order(:name) }

  def self.find_or_create_by_name!(name)
    normalized = name.to_s.strip.gsub(/\s+/, ' ')
    where('LOWER(name) = ?', normalized.downcase).first_or_create!(name: normalized)
  end

  private

  # Keeps book updated_at (used by the catalog feed's since filter and ETag) in step with
  # shelf renames and removals.
  def touch_books
    books.touch_all # rubocop:disable Rails/SkipsModelValidations -- timestamps only
  end

  def detach_books
    books.update_all(location_id: nil, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations -- mirrors dependent: :nullify
  end

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, ' ')
  end
end
