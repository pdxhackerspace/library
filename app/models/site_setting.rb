class SiteSetting < ApplicationRecord
  MATOMO_UNSAFE_CHARACTERS = /[<>"'\s]/

  validates :site_name, presence: true
  validates :loan_period_days, numericality: { only_integer: true, greater_than: 0 }
  validates :overdue_nag_interval_days, numericality: { only_integer: true, greater_than: 0 }
  validates :matomo_site_id, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validate :matomo_url_is_safe
  validate :matomo_site_id_required_when_url_present

  before_validation :normalize_matomo_fields

  def self.instance
    first_or_create!
  end

  def loan_period
    loan_period_days.days
  end

  def matomo_enabled?
    matomo_url.present? && matomo_site_id.present?
  end

  def matomo_tracker_base_url
    matomo_url.to_s.sub(%r{/\z}, '')
  end

  private

  def normalize_matomo_fields
    self.matomo_url = matomo_url.to_s.strip.sub(%r{/\z}, '').presence
    self.matomo_site_id = nil if matomo_url.blank?
  end

  def matomo_site_id_required_when_url_present
    return if matomo_url.blank?
    return if matomo_site_id.present?

    errors.add(:matomo_site_id, 'is required when Matomo URL is set')
  end

  def matomo_url_is_safe
    return if matomo_url.blank?

    uri = URI.parse(matomo_url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:matomo_url, 'is invalid')
      return
    end

    unless uri.scheme == 'https'
      errors.add(:matomo_url, 'must use HTTPS')
      return
    end

    errors.add(:matomo_url, 'is invalid') if matomo_url.match?(MATOMO_UNSAFE_CHARACTERS)
  rescue URI::InvalidURIError
    errors.add(:matomo_url, 'is invalid')
  end
end
