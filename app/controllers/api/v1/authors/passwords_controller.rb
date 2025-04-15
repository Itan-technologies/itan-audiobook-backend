class Api::V1::Authors::PasswordsController < Devise::PasswordsController
    respond_to :json
  
  # POST /api/v1/authors/password
  # Request password reset instructions
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    
    if successfully_sent?(resource)
      render json: {
        status: { code: 200, message: 'Reset password instructions sent successfully.' }
      }
    else
      render json: {
        status: { code: 422, message: 'Failed to send reset password instructions.' },
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/authors/password
  # Reset password with token
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    
    if resource.errors.empty?
      render json: {
        status: { code: 200, message: 'Password reset successfully.' }
      }
    else
      render json: {
        status: { code: 422, message: 'Failed to reset password.' },
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
