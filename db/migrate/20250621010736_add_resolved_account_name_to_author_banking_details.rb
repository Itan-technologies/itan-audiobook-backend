class AddResolvedAccountNameToAuthorBankingDetails < ActiveRecord::Migration[7.1]
  def change
    add_column :author_banking_details, :resolved_account_name, :string
  end
end
