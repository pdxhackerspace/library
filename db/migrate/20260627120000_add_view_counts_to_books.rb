class AddViewCountsToBooks < ActiveRecord::Migration[8.1]
  def change
    change_table :books, bulk: true do |t|
      t.integer :view_count, null: false, default: 0
      t.integer :borrow_count, null: false, default: 0
      t.integer :nfc_view_count, null: false, default: 0
    end
  end
end
