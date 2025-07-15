class AddTotalPagesToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :total_pages, :integer
  end
end
