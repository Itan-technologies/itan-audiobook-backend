class Api::V1::BooksController < ApplicationController
  # Load the book resource
  before_action :set_book, only: %i[show update destroy]
  
  # Author-specific actions
  before_action :authenticate_author!, only: %i[create update destroy my_books]
  before_action :authorize_author!, only: %i[update destroy]

  # GET /api/v1/books
  def index
    # Show only approved books to everyone
    @books = Book.includes(cover_image_attachment: :blob)
              .where(approval_status: 'approved')
              .order(created_at: :desc)

    render_books_json(@books)
  end

  # GET /api/v1/books/my_books
  def my_books
    @books = current_author.books.includes(cover_image_attachment: :blob).order(created_at: :desc)
    render_books_json(@books)
  end

  # GET /api/v1/books/:id
  def show
    render_books_json(@book)
  end

  # POST /api/v1/books

  def create
    @book = current_author.books.new(book_params)

    begin
      if create_book_with_attachments
        render_success_response(@book, 'Book created successfully.')
      else
        render_error_response(@book.errors.present? ? @book.errors.full_messages.join(', ') : 'Failed to create book')
      end
    rescue ActiveStorage::IntegrityError => e
      handle_integrity_error(e)
    rescue StandardError => e
      handle_standard_error(e)
    end
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

  def create_book_with_attachments
    return false unless @book.save

    # Verify attachments
    return true if @book.cover_image.attached? && @book.ebook_file.attached?

    # Clean up if attachments failed
    missing = []
    missing << 'cover image' unless @book.cover_image.attached?
    missing << 'ebook file' unless @book.ebook_file.attached?

    @book.destroy
    @book.errors.add(:base, "Failed to attach #{missing.join(' and ')}.")
    false
  end

  def render_success_response(book, message)
    render json: {
      status: { code: 200, message: message },
      data: BookSerializer.new(book).serializable_hash[:data][:attributes]
    }
  end

  def render_error_response(message, status = :unprocessable_entity)
    render json: {
      status: { code: status == :unprocessable_entity ? 422 : 500, message: message }
    }, status: status
  end

  def handle_integrity_error(error)
    @book.destroy if @book.persisted?
    Rails.logger.error "S3 Integrity Error: #{error.message}"
    Rails.logger.error "S3 Integrity Error details: #{error.backtrace.join("\n")}"
    render_error_response('Upload integrity error. Please try again.')
  end

  def handle_standard_error(error)
    Rails.logger.error "Error creating book: #{error.message}\n#{error.backtrace.join("\n")}"
    render_error_response("Server error: #{error.message}", :internal_server_error)
  end

  def render_books_json(books, message = nil, status_code = 200)
      response = {
        status: { code: status_code }
      }
      
      # Add message if provided
      response[:status][:message] = message if message
      
      # Handle both collections and single records
      if books.is_a?(Book)
        # Single book
        response[:data] = BookSerializer.new(books).serializable_hash[:data][:attributes]
      else
        # Collection of books
        response[:data] = BookSerializer.new(books).serializable_hash[:data].map { |book| book[:attributes] }
      end
      
      render json: response
  end

  # Used to manage error, record not found
  def set_book
    @book = Book.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: { code: 404, message: 'Book not found' }
    }, status: :not_found
  end

  def authorize_author!
    return if @book.author_id == current_author.id

    render json: {
      status: { code: 403, message: 'You are not authorized to perform this action' }
    }, status: :forbidden
  end

  def book_params
    params.require(:book).permit(:title, :description, :edition_number, contributors:[],
                                 :primary_audience, :publishing_rights,
                                 :ebook_price, :audiobook_price, :cover_image,
                                 :audiobook_file, :ebook_file, :ai_generated_image, :explicit_images,
                                 :subtitle, :bio, categories:[], keywords:[],
                                 :book_isbn, :terms_and_conditions, tags:[], :publisher, 
                                 :first_name, :last_name)
  end
end
