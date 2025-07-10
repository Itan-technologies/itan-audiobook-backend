class Api::V1::Authors::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # the first Google OAuth callback
  def google_oauth2
    # --- Using only Author.from_google for Google authentication ---
    # author = Author.from_omniauth(request.env['omniauth.auth'])

    omniauth_hash = request.env['omniauth.auth']
    google_params = {
      uid: omniauth_hash.uid,
      email: omniauth_hash.info.email
    }
    author = Author.from_google(google_params)

    if author.persisted?
      if author.two_factor_enabled
        session[:author_id_for_2fa] = author.id
        author.send_two_factor_code
        render json: {
          status: {
            code: 202,
            message: "Verification code sent to your #{author.preferred_2fa_method}",
            requires_verification: true,
            method: author.preferred_2fa_method
          }
        }
      else
        sign_in(author)
        respond_to do |format|
          format.html { redirect_to after_sign_in_path_for(author) }
          format.json do
            render json: {
              status: { code: 200, message: 'Signed in successfully' },
              data: AuthorSerializer.new(author).serializable_hash[:data][:attributes]
            }
          end
        end
      end
    else
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
