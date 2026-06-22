class AddSlackToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :slack_uid
      t.string :slack_name
    end
  end
end
