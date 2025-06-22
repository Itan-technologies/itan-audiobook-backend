class RenameAuthorPaymentDetailsToAuthorBankingDetails < ActiveRecord::Migration[7.1]
  def change
    rename_table :author_payment_details, :author_banking_details
  end
end
