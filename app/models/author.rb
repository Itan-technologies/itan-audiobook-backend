class Author < ApplicationRecord
  self.primary_key = :id
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Email validation
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email address' },
                    uniqueness: { case_sensitive: false }
  validates :phone_number, format: { with: /\A\+?[\d\s\-\(\)]+\z/, allow_blank: true }
  
  # associations
  has_many :notifications, as: :user
  has_many :books

  #Active storage attachment
  has_one_attached :author_profile_image

   # 2FA methods
  def generate_two_factor_code!
    # Generate a 6-digit code
    code = rand(100000..999999).to_s
    
    # Store the code with expiration time (10 minutes)
    update(
      two_factor_code: code,
      two_factor_code_expires_at: 10.minutes.from_now,
      two_factor_attempts: 0
    )
    
    code
  end

  def valid_two_factor_code?(code)
    # Check if code exists and hasn't expired
    return false if two_factor_code.nil? || two_factor_code_expires_at < Time.now
    
    # Increment attempts counter
    increment!(:two_factor_attempts)
    
    # After 5 attempts, invalidate code
    if two_factor_attempts >= 5
      clear_two_factor_code!
      return false
    end
    
    # Compare codes using secure comparison to prevent timing attacks
    ActiveSupport::SecurityUtils.secure_compare(two_factor_code.to_s, code.to_s)
  end

  def clear_two_factor_code!
    update(
      two_factor_code: nil,
      two_factor_code_expires_at: nil,
      two_factor_attempts: 0
    )
  end

  def send_two_factor_code
    code = generate_two_factor_code!
    
    if preferred_2fa_method == 'sms' && phone_verified?
      send_code_via_sms(code)
    else
      send_code_via_email(code)
    end
  end

  private
  
  def send_code_via_email(code)
    AuthorMailer.verification_code(self, code).deliver_now
  end
  
  def send_code_via_sms(code)
    begin
      client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
      client.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: phone_number,
        body: "Your verification code is: #{code}"
      )
    rescue => e
      Rails.logger.error "SMS sending failed: #{e.message}"
      # Fallback to email
      send_code_via_email(code)
    end
  end
end
