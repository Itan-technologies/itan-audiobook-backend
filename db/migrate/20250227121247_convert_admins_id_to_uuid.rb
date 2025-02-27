class ConvertAdminsIdToUuid < ActiveRecord::Migration[7.1]
  def up
    # First, remove existing indices
    remove_index :admins, :email if index_exists?(:admins, :email)
    remove_index :admins, :reset_password_token if index_exists?(:admins, :reset_password_token)
    
    # Add UUID column
    add_column :admins, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false
    
    # Set up for primary key change
    execute <<-SQL
      ALTER TABLE admins 
      DROP CONSTRAINT admins_pkey CASCADE;
    SQL
    
    # Drop the original ID column
    remove_column :admins, :id
    
    # Rename UUID column to ID and make it the primary key
    rename_column :admins, :uuid, :id
    execute <<-SQL
      ALTER TABLE admins
      ADD PRIMARY KEY (id);
    SQL
    
    # Now recreate indices
    add_index :admins, :email, unique: true
    add_index :admins, :reset_password_token, unique: true
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end