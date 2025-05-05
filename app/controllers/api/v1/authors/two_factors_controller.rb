require 'twilio-ruby'

class Api::V1::Authors::TwoFactorsController < ApplicationController
  before_action :authenticate_author!
  
  # Get 2FA status for the current author
  def status
    render json: {
      status: { code: 200 },
      data: {
        two_factor_enabled: current_author.two_factor_enabled,
        preferred_method: current_author.preferred_2fa_method,
        phone_number: current_author.phone_number,
        phone_verified: current_author.phone_verified
      }
    }
  end
  
  # Enable 2FA with email
  def enable_email
    current_author.update(
      two_factor_enabled: true,
      preferred_2fa_method: 'email'
    )
    
    render json: {
      status: { code: 200, message: "Two-factor authentication enabled with email" }
    }
  end
  
  # Setup SMS verification
  def setup_sms
    current_author.update(phone_number: params[:phone_number])
    
    # Send verification SMS
    code = current_author.generate_two_factor_code!
    
    begin
      client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
      client.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: current_author.phone_number,
        body: "Your phone verification code is: #{code}"
      )
      
      render json: {
        status: { code: 200, message: 'Verification code sent to your phone' }
      }
    rescue => e
      render json: {
        status: { code: 422, message: "Failed to send SMS: #{e.message}" }
      }, status: :unprocessable_entity
    end
  end
  
  # Verify SMS setup, verifies the verification code
  def verify_sms
    if current_author.valid_two_factor_code?(params[:verification_code])
      current_author.update(
        phone_verified: true,
        two_factor_enabled: true,
        preferred_2fa_method: 'sms'
      )
      current_author.clear_two_factor_code!
      
      render json: {
        status: { code: 200, message: 'Phone verified and 2FA enabled' },
        data: AuthorSerializer.new(current_author).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: { code: 422, message: 'Invalid verification code' }
      }, status: :unprocessable_entity
    end
  end
  
  # Disable 2FA
  def disable
    current_author.update(two_factor_enabled: false)
    render json: {
      status: { code: 200, message: "Two-factor authentication disabled" }
    }
  end
end
