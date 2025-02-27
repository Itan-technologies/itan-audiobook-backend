class Admins::SessionsController < Devise::SessionsController
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
      render json: {
        status: { code: 200, message: 'Admin logged in successfully.' },
        data: AdminSerializer.new(resource).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: { code: 401, message: "Admin couldn't be found." }
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    if current_admin
      render json: {
        status: 200,
        message: 'Admin logged out successfully.'
      }
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end
