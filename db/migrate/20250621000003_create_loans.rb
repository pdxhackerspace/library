class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      t.references :book, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :checked_out_at, null: false
      t.date :due_on, null: false
      t.datetime :returned_at
      t.text :notes

      t.timestamps
    end

    add_index :loans, :returned_at
    add_index :loans, :due_on
  end
end
