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
      
      response = PaystackService.resolve_account(account_number, bank_code)
      
      if response["status"] == true
        # Store the resolved account name
        self.resolved_account_name = response["data"]["account_name"]
        self.verified_at = Time.current
        self.save
        return true
      else
        errors.add(:account_number, "verification failed: #{response['message']}")
        return false
      end
    end
  end