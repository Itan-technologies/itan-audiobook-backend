class AddOmniauthToAuthors < ActiveRecord::Migration[7.1]
  def change
    add_column :authors, :provider, :string
    add_column :authors, :uid, :string
  end
end
