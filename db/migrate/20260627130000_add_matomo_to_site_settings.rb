class AddMatomoToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    change_table :site_settings, bulk: true do |t|
      t.string :matomo_url
      t.integer :matomo_site_id
    end
  end
end
