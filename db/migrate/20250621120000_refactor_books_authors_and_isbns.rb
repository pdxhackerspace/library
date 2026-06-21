class RefactorBooksAuthorsAndIsbns < ActiveRecord::Migration[8.1]
  class MigrationBook < ApplicationRecord
    self.table_name = 'books'
  end

  class MigrationAuthor < ApplicationRecord
    self.table_name = 'authors'
  end

  class MigrationBookAuthor < ApplicationRecord
    self.table_name = 'book_authors'
  end

  class MigrationIsbn < ApplicationRecord
    self.table_name = 'isbns'
  end

  def up
    create_table :authors do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :authors, :name, unique: true

    create_table :book_authors do |t|
      t.references :book, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :book_authors, %i[book_id author_id], unique: true

    create_table :isbns do |t|
      t.references :book, null: false, foreign_key: true
      t.string :code, null: false
      t.timestamps
    end
    add_index :isbns, :code

    add_column :books, :published_on, :date

    MigrationBook.reset_column_information
    MigrationBook.find_each do |book|
      migrate_legacy_author!(book)
      migrate_legacy_isbn!(book)
    end

    remove_column :books, :author, :string
    remove_column :books, :isbn, :string
    remove_index :books, :author if index_exists?(:books, :author)
  end

  def down
    add_column :books, :author, :string
    add_column :books, :isbn, :string
    add_index :books, :author

    MigrationBook.reset_column_information
    MigrationBook.find_each do |book|
      book.update!(
        author: book_authors_for(book).map(&:name).join(', '),
        isbn: book_isbns_for(book).first&.code
      )
    end

    remove_column :books, :published_on, :date
    drop_table :isbns
    drop_table :book_authors
    drop_table :authors
  end

  private

  def migrate_legacy_author!(book)
    return if book.author.blank?

    book.author.split(',').map(&:strip).reject(&:blank?).each_with_index do |name, index|
      author = MigrationAuthor.find_or_create_by!(name: name)
      MigrationBookAuthor.create!(book_id: book.id, author_id: author.id, position: index)
    end
  end

  def migrate_legacy_isbn!(book)
    return if book.isbn.blank?

    MigrationIsbn.create!(book_id: book.id, code: normalize_isbn(book.isbn))
  end

  def book_authors_for(book)
    MigrationBookAuthor.where(book_id: book.id).order(:position).filter_map do |book_author|
      MigrationAuthor.find_by(id: book_author.author_id)
    end
  end

  def book_isbns_for(book)
    MigrationIsbn.where(book_id: book.id).order(:id)
  end

  def normalize_isbn(raw)
    raw.to_s.gsub(/[^0-9X]/i, '').upcase
  end
end
