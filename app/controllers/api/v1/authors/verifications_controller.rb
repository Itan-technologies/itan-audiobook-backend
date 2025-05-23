class Api::V1::Authors::VerificationsController < ApplicationController
  # Verify 2FA code during login
  def verify
    author_id = session[:author_id_for_2fa]

    # Check if we have an author waiting for 2FA
    unless author_id
      return render json: {
        status: { code: 401, message: 'No verification in progress' }
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
          message: 'Invalid verification code or code expired',
          remaining_attempts: [5 - author.two_factor_attempts, 0].max
        }
      }, status: :unauthorized
    end
  end

  # Resend a new verification code
  def resend_verification
    # Check if we have a user in progress
    if session[:author_id_for_2fa].present?
      author = Author.find_by(id: session[:author_id_for_2fa])
      
      if author
        # Generate and send a new code
        author.send_two_factor_code
        
        render json: {
          status: {
            code: 200,
            message: "Verification code resent successfully",
            method: author.preferred_2fa_method
          }
        }
      else
        # Session exists but user not found
        render json: {
          status: { code: 401, message: "Session expired. Please login again." }
        }, status: :unauthorized
      end
    else
      # No active 2FA session
      render json: {
        status: { code: 401, message: "No active login session found." }
      }, status: :unauthorized
    end
  end
end
