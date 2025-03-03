class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :books, id: :uuid do |t|
      t.uuid :author_id, null: false
      t.string :title
      t.text :description
      t.string :edition_number
      t.string :contributors
      t.integer :primary_audience
      t.boolean :publishing_rights
      t.integer :duration
      t.integer :status
      t.integer :ebook_price
      t.integer :audiobook_price
      t.string :unique_book_id
      t.string :unique_audio_id

      t.timestamps
    end

    add_index :books, :author_id
    add_index :books, :unique_book_id, unique: true
    add_index :books, :unique_audio_id, unique: true
  end
end
