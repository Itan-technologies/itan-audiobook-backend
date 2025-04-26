class Api::V1::Readers::ProfilesController < ApplicationController
  before_action :authenticate_reader!
  respond_to :json

  def create
    if current_reader.update(readers_params)
      render json: {
        status: { code: 200, message: 'Profile updated successfully' },
        data: ReaderSerializer.new(current_reader).serializable_hash[:data][:attributes].merge(
          id: ReaderSerializer.new(current_reader).serializable_hash[:data][:id]
        )
      }
    else
      render json: {
        status: { code: 422, message: 'Unable to update profile' },
        errors: current_reader.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def show
    render json: {
      status: { code: 200 },
      data: ReaderSerializer.new(current_reader).serializable_hash[:data][:attributes].merge(
        id: ReaderSerializer.new(current_reader).serializable_hash[:data][:id]
      )
    }
  end

  private

  def readers_params
    params.require(:reader).permit(:first_name, :last_name, :email)
  end
end