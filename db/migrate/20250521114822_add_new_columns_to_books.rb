class AddNewColumnsToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :publisher, :string
    add_column :books, :first_name, :string
    add_column :books, :last_name, :string
    
    # For PostgreSQL array column - this works fine
    add_column :books, :tags, :string, array: true, default: []
    
    # For existing column, we need to specify the conversion method
    execute <<-SQL
      ALTER TABLE books 
      ALTER COLUMN keywords TYPE varchar[] 
      USING CASE 
        WHEN keywords IS NULL OR keywords = '' THEN '{}'::varchar[]
        ELSE string_to_array(keywords, ',')
      END;
    SQL

    # Add indexes for efficient querying of the arrays
    add_index :books, :tags, using: :gin
    add_index :books, :keywords, using: :gin
  end
end