class AddRevenueFieldsToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :paystack_fee, :decimal, precision: 10, scale: 2
    add_column :purchases, :delivery_fee, :decimal, precision: 10, scale: 2
    add_column :purchases, :admin_revenue, :decimal, precision: 10, scale: 2
    add_column :purchases, :author_revenue, :decimal, precision: 10, scale: 2
    add_column :purchases, :file_size_mb, :float
  end
end
