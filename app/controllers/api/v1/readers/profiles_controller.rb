class Api::V1::Readers::ProfilesController < ApplicationController
  before_action :authenticate_reader!
  respond_to :json

  def create
    if current_reader.update(reader_params)
      render json: {
        status: { code: 200, message: 'Profile created successfully' },
        data: current_reader
      }, status: :ok
    else
      render json: {
        status: { code: 401, message: 'Unable to create profile', errors: current_reader.errors.full_messages }
      }, status: :unauthorized
    end
  end

  def show
    render json: {
      status: { code: 200, message: 'Profile retrieved successfully' },
      data: current_reader
    }, status: :ok
  end

  private

  def reader_params
    params.require(:reader).permit(:name, :bio, :avatar) # <-- adjust these fields based on your Reader model
  end
end
