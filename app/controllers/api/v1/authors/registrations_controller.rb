class Api::V1::Authors::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def set_flash_message(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  def set_flash_message!(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
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
    params.require(:author).permit(:name, :email, :password)
  end

  # def account_update_params
  #   params.require(:author).permit(:name, :email, :password, :password_confirmation, :current_password)
  # end
end
