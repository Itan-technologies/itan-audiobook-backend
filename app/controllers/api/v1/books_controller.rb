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
             book[:attributes] 
            }
        }
    end

    # GET /api/v1/books/:id
    def show
        render json: {
            status: { code: 200 },
            data: BookSerializer.new(@book).serializable_hash[:data][:attributes]
            }
    end

    # POST /api/v1/books

    def create
      # Fix: Use current_author's association
      @book = current_author.books.new(book_params)
      
      # Handle both direct uploads and regular uploads
      if @book.save
        # Check if files were actually saved to S3
        if @book.cover_image.attached? && @book.ebook_file.attached?
          render json: {
            status: { code: 200, message: 'Book created successfully.' },
            data: BookSerializer.new(@book).serializable_hash[:data][:attributes]
          }
        else
          # Something went wrong with the uploads
          missing = []
          missing << "cover image" unless @book.cover_image.attached?
          missing << "ebook file" unless @book.ebook_file.attached?
          
          @book.destroy # Clean up the partial record
          
          render json: {
            status: { code: 422, message: "Book record created but failed to attach #{missing.join(' and ')}." }
          }, status: :unprocessable_entity
        end
      else
        render json: {
          status: { code: 422, message: @book.errors.full_messages.join(', ') }
        }, status: :unprocessable_entity
      end
      rescue ActiveStorage::IntegrityError => e
      @book.destroy if @book.persisted?
      Rails.logger.error "S3 Integrity Error: #{e.message}"
      Rails.logger.error "S3 Integrity Error details: #{e.backtrace.join("\n")}"
      render json: {
        status: { code: 422, message: "Upload integrity error. Please try again." }
      }, status: :unprocessable_entity
      rescue => e
      Rails.logger.error "Error creating book: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        status: { code: 500, message: "Server error: #{e.message}" }
      }, status: :internal_server_error
    end

    # PUT/PATCH /api/v1/books/:id
    def update
        if @book.update(book_params)
        render json: {
            status: { code: 200, message: 'Book updated successfully.' },
            data: BookSerializer.new(@book).serializable_hash[:data][:attributes]
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
