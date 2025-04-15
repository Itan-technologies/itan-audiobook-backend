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
      render json: {
        status: { code: 200, message: 'Author registered successfully.' },
        data: AuthorSerializer.new(resource).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: { code: 422, message: resource.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  def sign_up_params
    params.require(:author).permit(:name, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:author).permit(:name, :email, :password, :password_confirmation, :current_password)
  end
end
