class AddOverdueNagIntervalToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :overdue_nag_interval_days, :integer, default: 3, null: false
  end
end
