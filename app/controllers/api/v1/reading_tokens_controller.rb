class Api::V1::ReadingTokensController < ApplicationController
  before_action :authenticate_reader!

  def create
    book = Book.find(params[:book_id])
    content_type = params[:content_type]

    unless current_reader.trial_active? || current_reader.owns_book?(book)
      return render json: { error: 'Access denied. Please purchase this book, your free trial expired' },
                    status: :payment_required
    end

    token = JWT.encode(
      {
        sub: current_reader.id,
        book_id: book.id,
        content_type: content_type,
        exp: 4.hours.from_now.to_i
      },
      ENV.fetch('DEVISE_JWT_SECRET_KEY', nil),
      'HS256'
    )

    render json: { reading_token: token }
  end
end
