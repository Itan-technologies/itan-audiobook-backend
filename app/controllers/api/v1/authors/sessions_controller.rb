class Api::V1::Authors::SessionsController < Devise::SessionsController
  require 'net/http'
  require 'uri'
  require 'google-id-token' # Add this gem for verifying Google tokens

  include Recaptcha::Adapters::ControllerMethods

  respond_to :json

  # Skip authentication check for the sign-out action
  # protect_from_forgery with: :null_session
  
  # ✅ Skip reCAPTCHA for Google OAuth API
  
  
  # Create a session (email/password login)
  # Skip JWT authorization for google_oauth2
skip_before_action :authorize_request, only: [:google_oauth2]

  
  # ✅ Google OAuth API endpoint (JWT flow)
  
  # ✅ Skip authentication checks for these actions
  skip_before_action :authenticate_request, only: [:google_oauth2]
  skip_before_action :verify_signed_out_user, only: :destroy
  skip_before_action :verify_authenticity_token, only: [:google_oauth2]

   # ✅ Test endpoint to get current user
  def me
    render json: {
      user: AuthorSerializer.new(current_author).serializable_hash[:data][:attributes].merge(id: current_author.id)
    }
  end


  # ✅ Google OAuth API endpoint (JWT flow)
  def google_oauth2
    access_token = params[:access_token]

    if access_token.blank?
      render json: { error: "Missing Google access token" }, status: :bad_request
      return
    end

    begin
      # Fetch user info from Google API
      user_info_response = Faraday.get("https://www.googleapis.com/oauth2/v3/userinfo", {}, {
        Authorization: "Bearer #{access_token}"
      })

      user_info = JSON.parse(user_info_response.body)
      Rails.logger.info "Google user info: #{user_info}"

      if user_info["email"].blank?
        render json: { error: "Failed to fetch user info from Google" }, status: :unauthorized
        return
      end

      # Find or create Author
      author = Author.find_or_create_by(email: user_info["email"]) do |a|
        a.uid = user_info["sub"]
        a.provider = "google_oauth2"
        a.password = SecureRandom.hex(16)
        a.first_name = user_info["given_name"]
        a.last_name = user_info["family_name"]
        a.confirmed_at = Time.current # skip email confirmation
      end

      # Issue JWT token for API clients
      jwt_token = JwtService.encode(author_id: author.id)

      render json: {
        status: { code: 200, message: "Logged in successfully" },
        token: jwt_token,
        user: AuthorSerializer.new(author).serializable_hash[:data][:attributes].merge(id: author.id)
      }
    rescue => e
      Rails.logger.error "Google OAuth error: #{e.message}"
      render json: { error: "Google authentication failed" }, status: :internal_server_error
    end
  end

  # Helper method for 2FA handling
  def handle_two_factor_authentication
    session[:author_id_for_2fa] = resource.id
    resource.send_two_factor_code

    render json: {
      status: {
        code: 202,
        message: 'Verification code sent to your email or phone',
        requires_verification: true,
        method: resource.preferred_2fa_method
      }
    }, status: :accepted
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
      logger.info "Author #{current_author.id} signed out successfully"
    end

    render json: {
      status: 200,
      message: 'Logged out successfully.'
    }
  end

  def verify_recaptcha_token(token)
    uri = URI('https://www.google.com/recaptcha/api/siteverify')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    begin
      response = http.post(uri.path, URI.encode_www_form({
        secret: ENV.fetch('RECAPTCHA_SECRET_KEY', nil),
        response: token
      }))

      result = JSON.parse(response.body)
      recaptcha_valid = result['success'] == true

      Rails.logger.info "reCAPTCHA direct verification: #{result.inspect}"

      unless recaptcha_valid
        render json: {
          status: { code: 422, message: "reCAPTCHA verification failed: #{result['error-codes']}" }
        }, status: :unprocessable_entity
        return false
      end
      true
    rescue StandardError => e
      Rails.logger.error "reCAPTCHA verification error: #{e.message}"
      render json: {
        status: { code: 500, message: 'Failed to verify reCAPTCHA' }
      }, status: :internal_server_error
      false
    end
  end
end
