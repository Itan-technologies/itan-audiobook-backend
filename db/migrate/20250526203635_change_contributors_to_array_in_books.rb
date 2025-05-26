class ChangeContributorsToArrayInBooks < ActiveRecord::Migration[7.1]
  def up
    # First, convert existing data if any
    execute <<-SQL
      UPDATE books 
      SET contributors = ARRAY[contributors] 
      WHERE contributors IS NOT NULL AND contributors != '';
    SQL
    
    # Change the column type to array
    change_column :books, :contributors, :string, array: true, using: 'ARRAY[contributors]'
    
    # Add GIN index for better performance on array searches
    add_index :books, :contributors, using: :gin
  end

  def down
    # Remove the index first
    remove_index :books, :contributors
    
    # Convert back to single string (taking first element)
    execute <<-SQL
      UPDATE books 
      SET contributors = contributors[1] 
      WHERE contributors IS NOT NULL AND array_length(contributors, 1) > 0;
    SQL
    
    # Change back to regular string
    change_column :books, :contributors, :string, array: false
  end
end
