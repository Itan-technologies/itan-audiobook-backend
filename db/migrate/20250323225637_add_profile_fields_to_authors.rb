class AddProfileFieldsToAuthors < ActiveRecord::Migration[7.1]
  def change
    add_column :authors, :first_name, :string
    add_column :authors, :last_name, :string
    add_column :authors, :bio, :text
    add_column :authors, :phone_number, :string
    add_column :authors, :country, :string
    add_column :authors, :location, :string
  end
end
