class AddTwoFactorFieldsToAuthors < ActiveRecord::Migration[7.1]
  def change
    add_column :authors, :two_factor_enabled, :boolean, default: false
    add_column :authors, :preferred_2fa_method, :string, default: 'email'  
    add_column :authors, :phone_verified, :boolean, default: false
    add_column :authors, :two_factor_code, :string
    add_column :authors, :two_factor_code_expires_at, :datetime
    add_column :authors, :two_factor_attempts, :integer, default: 0
  end
end
