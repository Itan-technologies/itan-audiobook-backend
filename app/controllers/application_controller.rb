# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection

  # ✅ Protect browser-based requests with CSRF
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  # ✅ For API JSON requests, disable CSRF (for API clients)
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  # ✅ Before any API request, authenticate JWT
  before_action :authenticate_request

  before_action :authorize_request # ✅ Add this

  attr_reader :current_author

  private

  def authenticate_request
    header = request.headers['Authorization']
    if header.present?
      token = header.split(' ').last
      begin
        decoded = JwtService.decode(token)
        @current_author = Author.find(decoded['author_id'])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
        Rails.logger.error "JWT Authentication error: #{e.message}"
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    else
      render json: { error: 'Missing token' }, status: :unauthorized
    end
  end

  def authorize_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    if token.blank?
      render json: { error: 'Missing token' }, status: :unauthorized
      return
    end

    begin
      decoded = JwtService.decode(token)
      @current_author = Author.find(decoded[:author_id])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
      Rails.logger.error("JWT Auth error: #{e.message}")
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end
end
