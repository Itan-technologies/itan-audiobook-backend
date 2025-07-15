class RemoveDurationAndStatusFromBooks < ActiveRecord::Migration[7.1]
  def change
    remove_column :books, :duration, :integer
    remove_column :books, :status, :integer
  end
end
