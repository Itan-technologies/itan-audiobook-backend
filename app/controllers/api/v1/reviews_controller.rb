class Api::V1::ReviewsController < ApplicationController
    before_action :authenticate_reader!
  
    def create
      review = Review.new(review_params.merge(reader_id: current_reader.id))
      if review.save
        render json: review, status: :created
      else
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def destroy
      review = Review.find(params[:id])
      if review.reader_id == current_reader.id
        review.destroy
        head :no_content
      else
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  
    private
  
    def review_params
      params.require(:review).permit(:book_id, :rating, :comment)
    end
end
  