class Api::V1::Authors::ProfilesController < ApplicationController
  # before_action :authenticate_author!

   before_action :authorize_request # ✅ JWT auth instead

  # POST authors/profile
  def create
    update_profile('profile created successfully')
  end

  def show
    request.env["devise.mapping"] = Devise.mappings[:author]
    render json: {
      status: { code: 200, message: 'Profile successfully displayed' },
      data: AuthorSerializer.new(current_author).serializable_hash[:data][:attributes].merge(
        id: AuthorSerializer.new(current_author).serializable_hash[:data][:id]
      )
    }
  rescue StandardError => e
    Rails.logger.error("profile not displayed: #{e.message}")
    render json: {
      status: { code: 422, message: 'Unable to display profile' }
    }, status: :unprocessable_entity
  end

  def update
    update_profile('profile updated successfully')
  end

  private

  def update_profile(message)
    if current_author.update(profile_params)
      render json: {
        status: { code: 200, message: message },
        data: AuthorSerializer.new(current_author).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: { code: 422, message: current_author.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity

    end
  end

  def profile_params
    params.require(:author).permit(:first_name, :last_name, :bio, :phone_number, :country, :location,
                                   :author_profile_image, :two_factor_enabled, :preferred_2fa_method)
  end
end
