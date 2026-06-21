class AddLocationIdToBooks < ActiveRecord::Migration[8.1]
  class Book < ApplicationRecord
    self.table_name = 'books'
  end

  class Location < ApplicationRecord
    self.table_name = 'locations'
  end

  def up
    add_reference :books, :location, foreign_key: true

    Book.where.not(location: [nil, '']).find_each do |book|
      name = book.location.to_s.strip.gsub(/\s+/, ' ')
      next if name.blank?

      location = Location.where('LOWER(name) = ?', name.downcase).first_or_create!(name: name)
      book.update_column(:location_id, location.id)
    end

    remove_column :books, :location, :string
  end

  def down
    add_column :books, :location, :string

    execute <<~SQL.squish
      UPDATE books
      SET location = locations.name
      FROM locations
      WHERE books.location_id = locations.id
    SQL

    remove_reference :books, :location, foreign_key: true
  end
end
