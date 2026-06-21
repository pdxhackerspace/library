class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.string :isbn
      t.string :location
      t.text :notes

      t.timestamps
    end

    add_index :books, :title
    add_index :books, :author
  end
end
