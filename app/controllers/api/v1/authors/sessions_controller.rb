class Api::V1::Authors::SessionsController < Devise::SessionsController
  respond_to :json

  # Skip authentication check for the sign-out action
  skip_before_action :verify_signed_out_user, only: :destroy

  def set_flash_message(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  def set_flash_message!(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  # Create a session (login attempt)
  def create
    # First stage authentication with email/password
    self.resource = warden.authenticate!(auth_options)

    # Check if 2FA is enabled for this author
    if resource.two_factor_enabled?
      # Store author ID in session for verification step
      session[:author_id_for_2fa] = resource.id

      # Generate and send verification code
      resource.send_two_factor_code

      # Return response indicating 2FA is required
      render json: {
        status: {
          code: 202,
          message: 'Verification code sent to your email or phone',
          requires_verification: true,
          method: resource.preferred_2fa_method
        }
      }, status: :accepted
    else
      # No 2FA required, complete login
      sign_in(resource_name, resource)
      respond_with(resource)
    end
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: AuthorSerializer.new(resource).serializable_hash[:data][:attributes].merge(
          id: AuthorSerializer.new(resource).serializable_hash[:data][:id]
        )
      }
    else
      render json: {
        status: { code: 401, message: "Author couldn't be found." }
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    if current_author
      # Track successful logout if needed
      logger.info "Author #{current_author.id} signed out successfully"
    end

    render json: {
      status: 200,
      message: 'Logged out successfully.'
    }
  end
end
