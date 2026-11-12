class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_prefix, null: false
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :api_keys, :token_digest, unique: true
  end
end
