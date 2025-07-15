class AddApprovalStatusToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :approval_status, :string, default: 'pending'
    add_column :books, :admin_feedback, :text
  end
end
