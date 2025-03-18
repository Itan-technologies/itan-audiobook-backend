class Api::V1::BooksController < ApplicationController
    before_action :authenticate_author!, except: [:index, :show]
    before_action :set_book, only: [:show, :update, :destroy]
    before_action :authorize_author!, only: [:update, :destroy]

    # GET /api/v1/books
    def index
        @books = Book.includes(cover_image_attachment: :blob).order(created_at: :desc)
        render json: {
            status: {code: 200},
            data: BookSerializer.new(@books).serializable_hash[:data].map { |book| 
             book[:attributes].merge(id: book[:id]) 
            }
        }
    end

    # GET /api/v1/books/:id
    def show
        render json: {
            status: { code: 200 },
            data: BookSerializer.new(@book).serializable_hash[:data][:attributes].merge(
            id: BookSerializer.new(@book).serializable_hash[:data][:id]
                )
            }
    end

    # POST /api/v1/books
    def create
         if params[:book][:cover_image].present?
            file = params[:book][:cover_image]
            Rails.logger.info "File size: #{file.size}"
            Rails.logger.info "Content type: #{file.content_type}"
            Rails.logger.info "Original filename: #{file.original_filename}"
        end

        @book = current_author.books.new(book_params)
        if @book.save
            render json: {
                status: { code: 200, message: 'Book created successfully.' },
                data: BookSerializer.new(@book).serializable_hash[:data][:attributes].merge(
                id: BookSerializer.new(@book).serializable_hash[:data][:id]
                )
                }
        else
            render json: {
            status: { code: 422, message: @book.errors.full_messages.join(', ') }
            }
        end

    end

    # PUT/PATCH /api/v1/books/:id
    def update
        if @book.update(book_params)
        render json: {
            status: { code: 200, message: 'Book updated successfully.' },
            data: BookSerializer.new(@book).serializable_hash[:data][:attributes].merge(
            id: BookSerializer.new(@book).serializable_hash[:data][:id]
            )
        }
        else
        render json: {
            status: { code: 422, message: @book.errors.full_messages.join(', ') }
        }, status: :unprocessable_entity
        end
    end
    
    # DELETE /api/v1/books/:id
    def destroy
        @book.destroy
    
        render json: {
        status: { code: 200, message: 'Book deleted successfully.' }
        }
    end


    private

    #Used to manage error, record not found
    def set_book
            @book = Book.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render json: {
                status: { code: 404, message: 'Book not found' }
            }, status: :not_found
    end

    def authorize_author!
        unless @book.author_id == current_author.id
        render json: {
            status: {code: 403, message: 'You are not authorized to perform this action' }
        }, status: :forbidden
        end
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
