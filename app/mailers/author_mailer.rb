class AuthorMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  default from: 'omololuayk@gmail.com'

  def confirmation_instructions(record, token, opts = {})
    @confirmation_url = "#{ENV['FRONTEND_DOMAIN']}/auth/confirm?confirmation_token=#{token}&email=#{record.email}"
    super
  end
end
