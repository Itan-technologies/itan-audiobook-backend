class AddForeignKeyToBooks < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :books, :authors
  end
end
