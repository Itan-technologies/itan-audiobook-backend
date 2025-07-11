class Api::V1::Readers::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      serialized = ReaderSerializer.new(resource).serializable_hash[:data]
      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: serialized[:attributes].merge(id: serialized[:id])
      }, status: :ok
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
