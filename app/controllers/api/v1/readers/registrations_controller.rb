# app/controllers/api/v1/readers/registrations_controller.rb
class Api::V1::Readers::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: ReaderSerializer.new(resource).serializable_hash[:data][:attributes].merge(
          id: ReaderSerializer.new(resource).serializable_hash[:data][:id]
        )
      }
    else
      render json: {
        status: { code: 422, message: 'Reader could not be created.' },
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def sign_up_params
    params.require(:reader).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
