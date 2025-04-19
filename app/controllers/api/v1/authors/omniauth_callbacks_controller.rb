class Api::V1::Authors::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Google OAuth callback
  def google_oauth2
    @author = Author.from_omniauth(request.env["omniauth.auth"])

    if @author.persisted?
      # Check if 2FA is enabled for this author
      if @author.two_factor_enabled
        # Store author ID for verification
        session[:author_id_for_2fa] = @author.id
        # Send verification code
        @author.send_two_factor_code
        
        # Return partial sign-in response
        return render json: {
          status: {
            code: 202,
            message: "Verification code sent to your #{@author.preferred_2fa_method}",
            requires_verification: true,
            method: @author.preferred_2fa_method
          }
        }
      else
        # Complete sign in
        sign_in_and_redirect @author, event: :authentication
        
        # For API response if not redirecting
        return render json: {
          status: { code: 200, message: 'Signed in successfully with Google' },
          data: AuthorSerializer.new(@author).serializable_hash[:data][:attributes]
        }
      end
    else
      # Handle failure
      render json: {
        status: { code: 422, message: 'Google authentication failed' }
      }, status: :unprocessable_entity
    end
  end

  # Handle general OAuth failures
  def failure
    render json: {
      status: { code: 401, message: "Authentication failed: #{params[:message]}" }
    }, status: :unauthorized
  end
end
