class Api::V1::Authors::RegistrationsController < Devise::RegistrationsController
  require 'httparty'

  include Recaptcha::Adapters::ControllerMethods

  respond_to :json

  def set_flash_message(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  def set_flash_message!(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  # Override the create method to add reCAPTCHA verification
  def create
    # Add more verbose debugging
    params_token = params[:author][:captchaToken]
    Rails.logger.info "Token length: #{params_token&.length || 'nil'}"

    # Get specific error details from reCAPTCHA
    recaptcha_valid = false
    begin
      recaptcha_valid = verify_recaptcha(
        secret_key: ENV.fetch('RECAPTCHA_SECRET_KEY', nil),
        response: params_token # Explicitly pass the token
      )

      # Log the actual verification response for debugging
      if defined?(Recaptcha.last_verify_response) && Recaptcha.last_verify_response
        Rails.logger.info "reCAPTCHA response: #{Recaptcha.last_verify_response.inspect}"
      end
    rescue StandardError => e
      Rails.logger.error "reCAPTCHA error: #{e.message}"
    end

    Rails.logger.info "reCAPTCHA verification result: #{recaptcha_valid}"

    # Continue with your existing code...
    if recaptcha_valid
      # Remove captchaToken from params before calling super
      params[:author].delete(:captchaToken)
      super
    else
      render json: {
        status: { code: '422', message: 'reCAPTCHA verification failed' }
      }, status: :unprocessable_entity
    end
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      Rails.logger.info "Registration successful for #{resource.email}"
      render json: {
        status: { code: 200, message: 'Author registered successfully.' },
        data: AuthorSerializer.new(resource).serializable_hash[:data][:attributes]
      }
    else
      # Enhanced error logging
      error_messages = resource.errors.full_messages.join(', ')
      Rails.logger.error "Registration failed: #{error_messages}"

      # Return detailed error response
      render json: {
        status: {
          code: 422,
          message: error_messages,
          details: resource.errors.details
        }
      }, status: :unprocessable_entity
    end
  end

  def sign_up_params
    params.require(:author).permit(:email, :password, :captchaToken)
  end
end
