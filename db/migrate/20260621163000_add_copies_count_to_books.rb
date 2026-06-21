class AddCopiesCountToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :copies_count, :integer, null: false, default: 1
  end
end
