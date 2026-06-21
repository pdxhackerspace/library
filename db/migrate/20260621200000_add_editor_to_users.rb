class AddEditorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :editor, :boolean, null: false, default: false
  end
end
