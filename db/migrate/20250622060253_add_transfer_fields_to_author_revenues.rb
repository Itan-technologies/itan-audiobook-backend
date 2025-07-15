class AddTransferFieldsToAuthorRevenues < ActiveRecord::Migration[7.1]
  def change
    add_column :author_revenues, :transfer_reference, :string
    add_column :author_revenues, :transferred_at, :datetime
    add_column :author_revenues, :transfer_status, :string
  end
end
