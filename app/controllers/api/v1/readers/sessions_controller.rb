# app/controllers/api/v1/readers/sessions_controller.rb
class Api::V1::Readers::SessionsController < Devise::SessionsController
  respond_to :json

  # Add this line to fix the sign out issue
  skip_before_action :verify_signed_out_user, only: :destroy

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      # Extract JWT token from response headers (set by devise-jwt)
      token = response.headers['Authorization']
      
      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: ReaderSerializer.new(resource).serializable_hash[:data][:attributes].merge(
          id: ReaderSerializer.new(resource).serializable_hash[:data][:id],
          token: token&.split(' ')&.last  # Extract token from "Bearer TOKEN"
        )
      }
    else
      render json: {
        status: { code: 401, message: "Invalid email or password." }
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    render json: {
    status: { code: 200, message: 'Logged out successfully.' }
  }
  end
  
end
