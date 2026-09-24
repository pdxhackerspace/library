class AddMembersCanAddBooksToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :members_can_add_books, :boolean, null: false, default: false
  end
end
