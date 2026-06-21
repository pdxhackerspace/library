class Isbn < ApplicationRecord
  belongs_to :book

  validates :code, presence: true
  validate :code_must_be_valid_isbn

  before_validation :normalize_code

  private

  def normalize_code
    self.code = IsbnCode.normalize(code)
  end

  def code_must_be_valid_isbn
    return if code.blank?
    return if IsbnCode.valid?(code)

    errors.add(:code, 'must be a valid ISBN-10 or ISBN-13 code')
  end
end
