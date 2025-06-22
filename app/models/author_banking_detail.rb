class AuthorBankingDetail < ApplicationRecord
    # Associations
    belongs_to :author
    
    # Validations
    validates :account_name, presence: true
    validates :account_number, presence: true, 
              format: { with: /\A\d+\z/, message: "can only contain numbers" }
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
    
    # For serialization/display - don't expose full account numbers
    def as_json(options = {})
      super(options).tap do |json|
        if json["account_number"].present?
          json["account_number"] = sanitized_account_number
        end
      end
    end
    
    # Used when account details change
    def clear_verification!
      update!(verified_at: nil, recipient_code: nil)
    end

    def verify_account!
      return false unless account_number.present? && bank_code.present?
      
      # DEVELOPMENT MODE BYPASS - ESSENTIAL FOR TESTING
      if Rails.env.development? || Rails.env.test?
        Rails.logger.info "⚠️ DEVELOPMENT MODE: Using mock verification"
        
        # Mock successful verification
        self.resolved_account_name = "TEST ACCOUNT: #{account_name || 'Author Name'}"
        self.verified_at = Time.current
        self.recipient_code = "DEV_RCP_#{SecureRandom.hex(6)}"
        self.save
        return true
      end

      begin
        Rails.logger.info "Starting account verification with Paystack: #{account_number}, #{bank_code}"
        response = PaystackService.resolve_account(account_number, bank_code)
        Rails.logger.info "Paystack Response: #{response.inspect}"
        
        if response["status"] == true
          # Success path
          self.resolved_account_name = response["data"]["account_name"]
          self.verified_at = Time.current
          self.save
          return true
        else
          # Failed path - add the specific error message from Paystack
          error_message = response["message"] || "Unknown error"
          Rails.logger.error "Paystack verification failed: #{error_message}"
          
          # Provide more specific error messages based on the error code
          case response["code"]
          when "invalid_bank_code"
            errors.add(:bank_code, "is invalid. Please select a valid bank from the banks list.")
          when "invalid_account_number"
            errors.add(:account_number, "is invalid. Please check the account number.")
          else
            errors.add(:account_number, "verification failed: #{error_message}")
          end
          return false
        end
      rescue => e
        Rails.logger.error "Exception during verification: #{e.message}"
        errors.add(:base, "Verification service error: #{e.message}")
        return false
      end
    end
  end