class CreateAuthorRevenues < ActiveRecord::Migration[7.1]
  def change
    create_table :author_revenues, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :author, null: false, foreign_key: true, type: :uuid
      t.references :purchase, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :paid_at
      t.string :payment_batch_id
      t.string :payment_reference
      t.text :notes

      t.timestamps
    end
    
    # Add indexes for common queries
    add_index :author_revenues, :status
    add_index :author_revenues, :payment_batch_id
    add_index :author_revenues, :paid_at
  end
end