class SiteSetting < ApplicationRecord
  validates :site_name, presence: true
  validates :loan_period_days, numericality: { only_integer: true, greater_than: 0 }

  def self.instance
    first_or_create!
  end

  def loan_period
    loan_period_days.days
  end
end
