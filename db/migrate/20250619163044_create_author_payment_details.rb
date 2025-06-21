class CreateAuthorPaymentDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :author_payment_details, id: :uuid do |t|
      t.references :author, null: false, foreign_key: true, type: :uuid
      t.string :account_name
      t.string :account_number
      t.string :bank_code
      t.string :recipient_code  # Store Paystack recipient code
      t.datetime :verified_at
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :author_payment_details, :recipient_code, unique: true
  end
end
