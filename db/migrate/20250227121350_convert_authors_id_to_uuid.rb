class ConvertAuthorsIdToUuid < ActiveRecord::Migration[7.1]
  def up
    # First, remove existing indices to avoid conflicts
    remove_index :authors, :email if index_exists?(:authors, :email)
    remove_index :authors, :reset_password_token if index_exists?(:authors, :reset_password_token)
    remove_index :authors, :confirmation_token if index_exists?(:authors, :confirmation_token)
    
    # Add UUID column
    add_column :authors, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false
    
    # Handle any foreign keys pointing to authors here
    # For example, if you have a books table with author_id:
    # add_column :books, :author_uuid, :uuid
    # execute("UPDATE books SET author_uuid = (SELECT uuid FROM authors WHERE authors.id = books.author_id)")
    
    # Set up for primary key change
    execute <<-SQL
      ALTER TABLE authors
      DROP CONSTRAINT authors_pkey CASCADE;
    SQL
    
    # Drop the original ID column
    remove_column :authors, :id
    
    # Rename UUID column to ID and make it the primary key
    rename_column :authors, :uuid, :id
    execute <<-SQL
      ALTER TABLE authors
      ADD PRIMARY KEY (id);
    SQL
    
    # Recreate indices
    add_index :authors, :email, unique: true
    add_index :authors, :reset_password_token, unique: true
    add_index :authors, :confirmation_token, unique: true
    
    # Update foreign keys in related tables if needed
    # For the books example:
    # rename_column :books, :author_uuid, :author_id
    # add_foreign_key :books, :authors
    # remove_column :books, :author_id_integer
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end