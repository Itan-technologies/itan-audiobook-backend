class CreateLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :likes, id: :uuid do |t|
      t.uuid :book_id
      t.uuid :reader_id

      t.timestamps
    end
  end
end
