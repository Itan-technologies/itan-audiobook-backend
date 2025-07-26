# app/controllers/api/v1/readers/sessions_controller.rb
class Api::V1::Readers::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :verify_signed_out_user, only: :destroy

  def create
    self.resource = warden.authenticate!(auth_options)
    if resource
      # Generate JWT token manually (more reliable)
      token = generate_jwt_token(resource)

      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: ReaderSerializer.new(resource).serializable_hash[:data][:attributes].merge(
          id: ReaderSerializer.new(resource).serializable_hash[:data][:id],
          token: token
        )
      }
    end
  rescue StandardError => e
    Rails.logger.error "Login failed: #{e.message}"
    render json: {
      status: { code: 401, message: 'Invalid email or password.' }
    }, status: :unauthorized
  end

  def destroy
    render json: {
      status: { code: 200, message: 'Logged out successfully.' }
    }
  end

  private

  def generate_jwt_token(reader)
    payload = {
      sub: reader.id,
      email: reader.email,
      exp: 1.day.from_now.to_i,
      iat: Time.current.to_i
    }

    Rails.logger.info "Generating JWT with secret: #{ENV['DEVISE_JWT_SECRET_KEY'].present?}"
    JWT.encode(payload, ENV.fetch('DEVISE_JWT_SECRET_KEY', nil), 'HS256')
  end
end
