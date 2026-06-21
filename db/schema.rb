# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_21_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name", unique: true
  end

  create_table "book_authors", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_book_authors_on_author_id"
    t.index ["book_id", "author_id"], name: "index_book_authors_on_book_id_and_author_id", unique: true
    t.index ["book_id"], name: "index_book_authors_on_book_id"
  end

  create_table "book_subjects", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "subject_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "subject_id"], name: "index_book_subjects_on_book_id_and_subject_id", unique: true
    t.index ["book_id"], name: "index_book_subjects_on_book_id"
    t.index ["subject_id"], name: "index_book_subjects_on_subject_id"
  end

  create_table "books", force: :cascade do |t|
    t.integer "copies_count", default: 1, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "ebook_url"
    t.string "language"
    t.bigint "location_id"
    t.datetime "metadata_fetched_at"
    t.string "metadata_source"
    t.text "notes"
    t.integer "page_count"
    t.date "published_on"
    t.string "publisher"
    t.string "source_url"
    t.string "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_books_on_location_id"
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "isbns", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_isbns_on_book_id"
    t.index ["code"], name: "index_isbns_on_code"
  end

  create_table "loans", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "checked_out_at", null: false
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.text "notes"
    t.datetime "returned_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["book_id"], name: "index_loans_on_book_id"
    t.index ["due_on"], name: "index_loans_on_due_on"
    t.index ["returned_at"], name: "index_loans_on_returned_at"
    t.index ["user_id"], name: "index_loans_on_user_id"
  end

  create_table "locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "loan_period_days", default: 30, null: false
    t.string "site_name", default: "PDX Hackerspace Library", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subjects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_subjects_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "editor", default: false, null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "(provider IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "book_authors", "authors"
  add_foreign_key "book_authors", "books"
  add_foreign_key "book_subjects", "books"
  add_foreign_key "book_subjects", "subjects"
  add_foreign_key "books", "locations"
  add_foreign_key "isbns", "books"
  add_foreign_key "loans", "books"
  add_foreign_key "loans", "users"
end
