class AddTrialFieldsToReaders < ActiveRecord::Migration[7.1]
  def change
    add_column :readers, :trial_start, :datetime
    add_column :readers, :trial_end, :datetime
  end
end
