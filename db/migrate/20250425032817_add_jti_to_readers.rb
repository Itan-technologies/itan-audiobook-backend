class AddJtiToReaders < ActiveRecord::Migration[7.1]
  def change
    add_column :readers, :jti, :string, null: false
    add_index :readers, :jti, unique: true
  end  
end
