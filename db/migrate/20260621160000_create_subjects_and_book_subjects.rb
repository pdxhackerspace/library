class CreateSubjectsAndBookSubjects < ActiveRecord::Migration[8.1]
  class MigrationBook < ApplicationRecord
    self.table_name = 'books'
  end

  class MigrationSubject < ApplicationRecord
    self.table_name = 'subjects'
  end

  class MigrationBookSubject < ApplicationRecord
    self.table_name = 'book_subjects'
  end

  def up
    create_table :subjects do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :subjects, :name, unique: true

    create_table :book_subjects do |t|
      t.references :book, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :book_subjects, %i[book_id subject_id], unique: true

    migrate_legacy_subjects!

    remove_column :books, :subjects, :jsonb
  end

  def down
    add_column :books, :subjects, :jsonb, null: false, default: []

    MigrationBookSubject.delete_all
    drop_table :book_subjects
    drop_table :subjects
  end

  private

  def migrate_legacy_subjects!
    MigrationBook.find_each do |book|
      Array(book.subjects).each_with_index do |value, index|
        name = extract_subject_name(value)
        next if name.blank?

        subject = MigrationSubject.find_or_create_by!(name: name)
        MigrationBookSubject.create!(book_id: book.id, subject_id: subject.id, position: index)
      end
    end
  end

  def extract_subject_name(value)
    case value
    when String
      value.strip.presence
    when Hash
      value['name'].to_s.strip.presence
    else
      value.to_s.strip.presence
    end
  end
end
