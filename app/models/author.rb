class Author < ApplicationRecord
  self.primary_key = :id
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # Email validation
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email address' },
                    uniqueness: { case_sensitive: false }
  validates :phone_number, format: { with: /\A\+?[\d\s\-\(\)]+\z/, allow_blank: true }

  # associations
  has_many :notifications
  has_many :books
  has_many :author_revenues
  has_many :purchases, through: :books
  has_one :author_banking_detail, dependent: :destroy

  # Active storage attachment
  has_one_attached :author_profile_image

  # 2FA methods
  def generate_two_factor_code!
    # Generate a 6-digit code
    code = rand(100_000..999_999).to_s

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

  # Add this method for OAuth functionality
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |author|
      author.email = auth.info.email
      author.password = Devise.friendly_token[0, 20]
      author.first_name = auth.info.first_name
      author.last_name = auth.info.last_name

      # Attach profile image if available
      attach_profile_image(author, auth.info.image) if auth.info.image
    end
  end

  def self.attach_profile_image(author, image_url)
    temp_file = Down.download(
      image_url,
      max_size: 5 * 1024 * 1024, # 5MB limit
      max_redirects: 2
    )
    author.author_profile_image.attach(
      io: temp_file,
      filename: "profile_#{SecureRandom.hex(8)}.jpg",
      content_type: temp_file.content_type
    )
  rescue Down::Error => e
    Rails.logger.error "Profile image download failed: #{e.message}"
  ensure
    temp_file&.close if temp_file.respond_to?(:close)
  end

  def total_earnings
    author_revenues.sum(:amount)
  end
  
  def pending_earnings
    author_revenues.pending.sum(:amount)
  end
  
  def paid_earnings
    author_revenues.approved.sum(:amount)
  end
  
  def monthly_earnings(year = Date.current.year)
    author_revenues
      .where('extract(year from created_at) = ?', year)
      .group("extract(month from created_at)")
      .sum(:amount)
  end
  
  def book_earnings
    author_revenues
      .joins(purchase: :book)
      .group('books.id, books.title')
      .sum(:amount)
  end

  private

  def send_code_via_email(code)
    AuthorMailer.verification_code(self, code).deliver_now
  end

  def send_code_via_sms(code)
    client = Twilio::REST::Client.new(ENV.fetch('TWILIO_ACCOUNT_SID', nil), ENV.fetch('TWILIO_AUTH_TOKEN', nil))
    client.messages.create(
      from: ENV.fetch('TWILIO_PHONE_NUMBER', nil),
      to: phone_number,
      body: "Your verification code is: #{code}"
    )
  rescue StandardError => e
    Rails.logger.error "SMS sending failed: #{e.message}"
    # Fallback to email
    send_code_via_email(code)
  end
end
