class RenameAuthorRevenueColumn < ActiveRecord::Migration[7.1]
  def change
    rename_column :purchases, :author_revenue, :author_revenue_amount
  end
end
