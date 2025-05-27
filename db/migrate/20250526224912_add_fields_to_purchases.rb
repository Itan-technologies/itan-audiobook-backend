class AddFieldsToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :transaction_reference, :string
    add_column :purchases, :payment_verified_at, :datetime
    add_column :purchases, :reader_id, :uuid

    # Add indexes
   add_index :purchases, :transaction_reference, unique: true
   add_index :purchases, [:reader_id, :book_id]
   add_index :purchases, :reader_id
   
   # Add foreign key constraint
   add_foreign_key :purchases, :readers
  end   
end
