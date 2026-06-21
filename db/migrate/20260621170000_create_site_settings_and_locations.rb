class CreateSiteSettingsAndLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :site_name, null: false, default: 'PDX Hackerspace Library'
      t.integer :loan_period_days, null: false, default: 30
      t.timestamps
    end

    create_table :locations do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :locations, :name, unique: true
  end
end
