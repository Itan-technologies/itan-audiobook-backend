class Authors::ProfilesController < ApplicationController
    before_action :authenticate_author!

    # POST authors/profile
    def create
       update_profile('profile created successfully')
    end

    def show             
            render json: {
                status: {code: 200 },
                data: AuthorSerializer.new(current_author).serializable_hash[:data][:attributes]
            }
    end

    def update
        update_profile('profile updated successfully')
    end

    private

    def update_profile(message)
        if current_author.update(profile_params)
            render json: {
                status: { code: 200, message: message},
                data: AuthorSerializer.new(current_author).serializable_hash[:data][:attributes]
            }
        else 
            render json: {
                status: { code: 422, message: current_author.errors.full_messages.join(', ') }
            }, status: :unprocessable_entity
    
        end
    end

    def profile_params
        params.require(:author).permit(  :first_name, :last_name, :bio, :phone_number, :country, :location )                             
    end
    
end
