class AuthorMailer < Devise::Mailer
  
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  default from: 'omololuayk@gmail.com'
  
  def confirmation_instructions(record, token, opts = {})
    @confirmation_url = "http://localhost:3000/authors/confirmation?confirmation_token=#{token}"
    super
  end
end