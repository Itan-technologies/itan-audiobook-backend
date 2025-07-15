class AuthorBankingDetail < ApplicationRecord
  # Associations
  belongs_to :author

  # Validations
  validates :account_name, presence: true
  validates :account_number, presence: true,
                             format: { with: /\A\d+\z/, message: 'can only contain numbers' }
  validates :bank_code, presence: true
  validates :recipient_code, uniqueness: { allow_nil: true }

  # Scopes
  scope :verified, -> { where.not(verified_at: nil) }
  scope :active, -> { where(active: true) }

  # Methods
  def verified?
    verified_at.present?
  end

  def mark_as_verified!
    update!(verified_at: Time.current)
  end

  # For PCI compliance - we don't want full account numbers in logs
  def sanitized_account_number
    return nil unless account_number.present?

    "XXXX#{account_number.last(4)}"
  end

  # For serialization/display
  def as_json(options = {})
    super.tap do |json|
      json['account_number'] = sanitized_account_number if json['account_number'].present?
    end
  end

  # Used when account details change
  def clear_verification!
    update!(verified_at: nil, recipient_code: nil)
  end

  def verify_account!
    return false unless account_number.present? && bank_code.present?

    begin
      Rails.logger.info "Starting account verification with Paystack: #{account_number}, #{bank_code}"
      response = PaystackService.resolve_account(account_number, bank_code)
      Rails.logger.info "Paystack Response: #{response.inspect}"

      if response['status'] == true
        # Success path: resolve account succeeded
        self.resolved_account_name = response['data']['account_name']
        self.verified_at = Time.current

        # Now create transfer recipient with Paystack
        recipient_result = PaystackService.new.create_transfer_recipient(
          name: resolved_account_name,
          account_number: account_number,
          bank_code: bank_code
        )
        if recipient_result[:success]
          self.recipient_code = recipient_result[:data]['recipient_code']
          save
          true
        else
          errors.add(:base, "Failed to create transfer recipient: #{recipient_result[:error]}")
          false
        end
      else
        # Failed path - add the specific error message from Paystack
        error_message = response['message'] || 'Unknown error'
        Rails.logger.error "Paystack verification failed: #{error_message}"

        # Provide more specific error messages based on the error code
        case response['code']
        when 'invalid_bank_code'
          errors.add(:bank_code, 'is invalid. Please select a valid bank from the banks list.')
        when 'invalid_account_number'
          errors.add(:account_number, 'is invalid. Please check the account number.')
        else
          errors.add(:account_number, "verification failed: #{error_message}")
        end
        false
      end
    rescue StandardError => e
      Rails.logger.error "Exception during verification: #{e.message}"
      errors.add(:base, "Verification service error: #{e.message}")
      false
    end
  end
end
