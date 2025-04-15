class Api::V1::Authors::VerificationsController < ApplicationController
  # Verify 2FA code during login
  def verify
    author_id = session[:author_id_for_2fa]
    
    # Check if we have an author waiting for 2FA
    unless author_id
      return render json: {
        status: { code: 401, message: "No verification in progress" }
      }, status: :unauthorized
    end
    
    author = Author.find(author_id)
    
    # Validate verification code
    if author.valid_two_factor_code?(params[:verification_code])
      # Clear the code and session data
      author.clear_two_factor_code!
      session.delete(:author_id_for_2fa)
      
      # Complete sign in
      sign_in(:author, author)
      
      # Return success with author data
      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: AuthorSerializer.new(author).serializable_hash[:data][:attributes].merge(
          id: AuthorSerializer.new(author).serializable_hash[:data][:id]
        )
      }
    else
      render json: {
        status: { 
          code: 401, 
          message: "Invalid verification code or code expired",
          remaining_attempts: [5 - author.two_factor_attempts, 0].max
        }
      }, status: :unauthorized
    end
  end
  
  # Request a new verification code
  def resend
    author_id = session[:author_id_for_2fa]
    
    unless author_id
      return render json: {
        status: { code: 401, message: "No verification in progress" }
      }, status: :unauthorized
    end
    
    author = Author.find(author_id)
    author.send_two_factor_code
    
    render json: {
      status: { code: 200, message: 'New verification code sent' }
    }
  end
end