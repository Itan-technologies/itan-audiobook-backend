class AddFeeDataSourceToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :fee_data_source, :string
  end
end
