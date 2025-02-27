class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases, id: :uuid do |t|
      # t.references :listener, null: false, foreign_key: true, type: :uuid
      t.references :book, null: false, foreign_key: true, type: :uuid
      t.integer :amount
      t.string :content_type
      t.string :purchase_status
      t.timestamp :purchase_date

      t.timestamps
    end
  end
end
