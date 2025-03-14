class Admins::SessionsController < Devise::SessionsController
  respond_to :json

  # Skip authentication check for the sign-out action
  skip_before_action :verify_signed_out_user, only: :destroy

  def set_flash_message(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  def set_flash_message!(key, kind, options = {})
    # Do nothing as flash is not available in API-only apps
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Admin logged in successfully.' },
        data: AdminSerializer.new(resource).serializable_hash[:data][:attributes].merge(
        id: AdminSerializer.new(resource).serializable_hash[:data][:id]
        )
      }
    else
      render json: {
        status: { code: 401, message: "Admin couldn't be found." }
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    if current_admin
      # Track successful logout if needed
      logger.info "Admin #{current_admin.id} signed out successfully"
    end
    
    render json: {
      status: 200,
      message: 'Logged out successfully.'
    }
  end
end
