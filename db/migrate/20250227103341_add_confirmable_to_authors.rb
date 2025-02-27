class AddConfirmableToAuthors < ActiveRecord::Migration[7.1]
  def change
    add_column :authors, :confirmation_token, :string
    add_column :authors, :confirmed_at, :datetime
    add_column :authors, :confirmation_sent_at, :datetime
    add_column :authors, :unconfirmed_email, :string
  
  # Add an index for the confirmation token
  add_index :authors, :confirmation_token, unique: true
  end
end
