class AddColumnsToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :ai_generated_image, :boolean
    add_column :books, :explicit_images, :boolean
    add_column :books, :subtitle, :string
    add_column :books, :bio, :text
    add_column :books, :categories, :string
    add_column :books, :keywords, :string
    add_column :books, :book_isbn, :integer
    add_column :books, :terms_and_conditions, :boolean
  end
end
