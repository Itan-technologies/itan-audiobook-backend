class Api::V1::BooksController < ApplicationController
    before_action :authenticate_author!, except: [:index, :show]

    def create
        @book = current_author.books.new(book_params)
        if @book.save
            render json: {
                status: { code: 200, message: 'Book created successfully.' },
                data: BookSerializer.new(@book).serializable_hash[:data][:attributes]
                }
        else
            render json: {
            status: { code: 422, message: @book.errors.full_messages.join(', ') }
            }

    end

    def book_params
        params.require(:book).permit(   :title, :description, :edition_number, :contributors,
                                        :primary_audience, :publishing_rights,
                                        :ebook_price, :audiobook_price, :cover_image,
                                        :audiobook_file, :ebook_file, :ai_generated_image, :explicit_images,
                                        :subtitle, :bio, :categories, :keywords,
                                        :book_isbn, :terms_and_conditions
                                    )
    end
end
