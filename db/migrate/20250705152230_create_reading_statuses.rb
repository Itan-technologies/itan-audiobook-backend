class CreateReadingStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :reading_statuses, id: :uuid do |t|
      t.uuid :reader_id
      t.uuid :book_id
      t.string :status
      t.datetime :last_read_at

      t.timestamps
    end
    add_index :reading_statuses, [:reader_id, :book_id], unique: true
  end
end
