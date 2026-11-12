class ApiKey < ApplicationRecord
  TOKEN_PREFIX = 'lib_'.freeze
  LAST_USED_RESOLUTION = 1.minute

  belongs_to :created_by, class_name: 'User', optional: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true

  scope :ordered, -> { order(:name, :id) }

  attr_reader :token

  # Builds a key with a fresh random token. The plain token is only available
  # on this instance (via #token); the database stores a SHA-256 digest.
  def self.generate(**attributes)
    token = "#{TOKEN_PREFIX}#{SecureRandom.base58(32)}"
    new(**attributes, token_digest: digest(token), token_prefix: token.first(TOKEN_PREFIX.length + 6))
      .tap { |key| key.instance_variable_set(:@token, token) }
  end

  def self.authenticate(token)
    return nil if token.blank?

    find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def record_use!
    return if last_used_at && last_used_at > LAST_USED_RESOLUTION.ago

    update_column(:last_used_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
