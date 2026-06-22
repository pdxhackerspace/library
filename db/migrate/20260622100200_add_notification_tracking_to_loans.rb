class AddNotificationTrackingToLoans < ActiveRecord::Migration[8.1]
  def change
    change_table :loans, bulk: true do |t|
      t.date :due_notified_on
      t.datetime :overdue_nagged_at
    end
  end
end
