class AddMetadataToBooks < ActiveRecord::Migration[8.1]
  def change
    change_table :books, bulk: true do |t|
      t.string :subtitle
      t.text :description
      t.string :publisher
      t.integer :page_count
      t.string :language
      t.jsonb :subjects, null: false, default: []
      t.string :metadata_source
      t.datetime :metadata_fetched_at
      t.string :source_url
    end
  end
end
