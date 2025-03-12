class AudioProcessingFieldsToBooks < ActiveRecord::Migration[7.1]
  def change 
    add_column :books, :total_chunks, :integer 
    add_column :books, :processed_chunks, :integer
  end
end
