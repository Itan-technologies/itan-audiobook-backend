# app/controllers/api/v1/readers/sessions_controller.rb
class Api::V1::Readers::SessionsController < Devise::SessionsController
  respond_to :json

  # Fix the sign out issue (good catch)
  skip_before_action :verify_signed_out_user, only: :destroy

  private

  def respond_with(resource, _opts = {})
    serialized = ReaderSerializer.new(resource).serializable_hash[:data]

    render json: {
      status: { code: 200, message: 'Logged in successfully.' },
      data: serialized[:attributes].merge(id: serialized[:id])
    }, status: :ok
  end

  def respond_to_on_destroy
    if current_reader
      render json: {
        status: { code: 200, message: 'Logged out successfully.' }
      }, status: :ok
    else
      render json: {
        status: { code: 401, message: 'No active session found.' }
      }, status: :unauthorized
    end
  end
end
