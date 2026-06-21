class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :password_digest
      t.boolean :admin, null: false, default: false
      t.string :provider
      t.string :uid

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, %i[provider uid], unique: true, where: 'provider IS NOT NULL'
  end
end
