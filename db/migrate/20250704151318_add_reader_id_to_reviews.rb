class AddReaderIdToReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :reviews, :reader_id, :uuid
    add_index :reviews, :reader_id
  end
end
