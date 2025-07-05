class Api::V1::LikesController < ApplicationController
    before_action :authenticate_reader!
  
    def create
      like = Like.new(book_id: params[:book_id], reader_id: current_reader.id)
      if like.save
        render json: like, status: :created
      else
        render json: { errors: like.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def destroy
      like = Like.find_by(id: params[:id], reader_id: current_reader.id)
      if like
        like.destroy
        head :no_content
      else
        render json: { error: "Not found" }, status: :not_found
      end
    end
end
  