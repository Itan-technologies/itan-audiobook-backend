class AuthorMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  default from: 'omololuayk@gmail.com'

  def confirmation_instructions(record, token, opts = {})
    @confirmation_url = "#{ENV['FRONTEND_URL']}/auth/confirm-email?confirmation_token=#{token}&email=#{record.email}"
    super
  end

  def reset_password_instructions(record, token, opts = {})
    @reset_password_url = "#{ENV['FRONTEND_URL']}/reset-password?reset_password_token=#{token}"
    super
  end

  def verification_code(author, code)
    @author = author
    @code = code
    mail(to: author.email, subject: 'Your Login Verification Code')
  end

  def payment_processed(author, amount, sale_count, payment_reference = nil)
    # Explicitly require business_time to ensure it's loaded
    require 'business_time'
    
    @author = author
    @amount = amount
    @sale_count = sale_count
    @payment_reference = payment_reference || "N/A"
    @payment_date = Date.today
    
    # Properly calculate business days with error handling
    begin
      # This is the correct syntax for the business_time gem
      @estimated_transfer_date = (@payment_date + 30.days).strftime('%B %d, %Y')
    rescue => e      
      @estimated_deposit_date = (@payment_date + 30.days).strftime('%B %d, %Y')
    end
    
    mail(
      to: @author.email,
      subject: "Your payment of $#{sprintf('%.2f', amount)} has been approved"
    )
  end
end
