class ChangeCategoriesToArrayInBooks < ActiveRecord::Migration[7.1]
  def up
    # First, convert existing data if any
    execute <<-SQL
      UPDATE books 
      SET categories = ARRAY[categories] 
      WHERE categories IS NOT NULL AND categories != '';
    SQL
    
    # Change the column type to array
    change_column :books, :categories, :string, array: true, using: 'ARRAY[categories]'
    
    # Add GIN index for better performance on array searches
    add_index :books, :categories, using: :gin
  end

  def down
    # Remove the index first
    remove_index :books, :categories
    
    # Convert back to single string (taking first element)
    execute <<-SQL
      UPDATE books 
      SET categories = categories[1] 
      WHERE categories IS NOT NULL AND array_length(categories, 1) > 0;
    SQL
    
    # Change back to regular string
    change_column :books, :categories, :string, array: false
  end
end
