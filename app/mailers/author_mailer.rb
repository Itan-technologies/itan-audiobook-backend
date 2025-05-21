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
end
