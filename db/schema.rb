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

ActiveRecord::Schema[7.1].define(version: 2025_06_22_060253) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "author_banking_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id", null: false
    t.string "account_name"
    t.string "account_number"
    t.string "bank_code"
    t.string "recipient_code"
    t.datetime "verified_at"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resolved_account_name"
    t.index ["author_id"], name: "index_author_banking_details_on_author_id"
    t.index ["recipient_code"], name: "index_author_banking_details_on_recipient_code", unique: true
  end

  create_table "author_revenues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id", null: false
    t.uuid "purchase_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.datetime "paid_at"
    t.string "payment_batch_id"
    t.string "payment_reference"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transfer_reference"
    t.datetime "transferred_at"
    t.string "transfer_status"
    t.index ["author_id"], name: "index_author_revenues_on_author_id"
    t.index ["paid_at"], name: "index_author_revenues_on_paid_at"
    t.index ["payment_batch_id"], name: "index_author_revenues_on_payment_batch_id"
    t.index ["purchase_id"], name: "index_author_revenues_on_purchase_id"
    t.index ["status"], name: "index_author_revenues_on_status"
  end

  create_table "authors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "first_name"
    t.string "last_name"
    t.text "bio"
    t.string "phone_number"
    t.string "country"
    t.string "location"
    t.boolean "two_factor_enabled", default: false
    t.string "preferred_2fa_method", default: "email"
    t.boolean "phone_verified", default: false
    t.string "two_factor_code"
    t.datetime "two_factor_code_expires_at"
    t.integer "two_factor_attempts", default: 0
    t.string "provider"
    t.string "uid"
    t.index ["confirmation_token"], name: "index_authors_on_confirmation_token", unique: true
    t.index ["email"], name: "index_authors_on_email", unique: true
    t.index ["reset_password_token"], name: "index_authors_on_reset_password_token", unique: true
  end

  create_table "books", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id", null: false
    t.string "title"
    t.text "description"
    t.string "edition_number"
    t.jsonb "contributors"
    t.integer "primary_audience"
    t.boolean "publishing_rights"
    t.integer "ebook_price"
    t.integer "audiobook_price"
    t.string "unique_book_id"
    t.string "unique_audio_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ai_generated_image"
    t.boolean "explicit_images"
    t.string "subtitle"
    t.text "bio"
    t.jsonb "categories"
    t.string "keywords", array: true
    t.integer "book_isbn"
    t.boolean "terms_and_conditions"
    t.string "approval_status", default: "pending"
    t.text "admin_feedback"
    t.string "publisher"
    t.string "first_name"
    t.string "last_name"
    t.string "tags", default: [], array: true
    t.integer "total_pages"
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["categories"], name: "index_books_on_categories", using: :gin
    t.index ["contributors"], name: "index_books_on_contributors", using: :gin
    t.index ["keywords"], name: "index_books_on_keywords", using: :gin
    t.index ["tags"], name: "index_books_on_tags", using: :gin
    t.index ["unique_audio_id"], name: "index_books_on_unique_audio_id", unique: true
    t.index ["unique_book_id"], name: "index_books_on_unique_book_id", unique: true
  end

  create_table "chapters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "book_id", null: false
    t.string "title"
    t.text "content"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_chapters_on_book_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "user_type", null: false
    t.uuid "user_id", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type", "user_id"], name: "index_notifications_on_user"
  end

  create_table "purchases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "book_id", null: false
    t.integer "amount"
    t.string "content_type"
    t.string "purchase_status"
    t.datetime "purchase_date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_reference"
    t.datetime "payment_verified_at"
    t.uuid "reader_id"
    t.decimal "paystack_fee", precision: 10, scale: 2
    t.decimal "delivery_fee", precision: 10, scale: 2
    t.decimal "admin_revenue", precision: 10, scale: 2
    t.decimal "author_revenue_amount", precision: 10, scale: 2
    t.float "file_size_mb"
    t.string "fee_data_source"
    t.index ["book_id"], name: "index_purchases_on_book_id"
    t.index ["reader_id", "book_id"], name: "index_purchases_on_reader_id_and_book_id"
    t.index ["reader_id"], name: "index_purchases_on_reader_id"
    t.index ["transaction_reference"], name: "index_purchases_on_transaction_reference", unique: true
  end

  create_table "readers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.index ["email"], name: "index_readers_on_email", unique: true
    t.index ["jti"], name: "index_readers_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_readers_on_reset_password_token", unique: true
  end

  create_table "reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rating"
    t.text "comment"
    t.uuid "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_reviews_on_book_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "author_banking_details", "authors"
  add_foreign_key "author_revenues", "authors"
  add_foreign_key "author_revenues", "purchases"
  add_foreign_key "books", "authors"
  add_foreign_key "chapters", "books"
  add_foreign_key "purchases", "books"
  add_foreign_key "purchases", "readers"
  add_foreign_key "reviews", "books"
end
