class Api::V1::BooksController < ApplicationController
  # Load the book resource
  before_action :set_book, only: %i[show update destroy]
  
  # Author-specific actions
  before_action :authenticate_author!, only: %i[create update destroy my_books]
  before_action :authorize_author!, only: %i[update destroy]

  # Normalize JSON arrays for book attributes
  before_action :normalize_json_arrays, only: %i[create update]

  before_action :convert_price_to_cents, only: %i[create update]

  respond_to :json

  # GET /api/v1/books # Show only approved books to everyone
  def index    
    @books = Book.includes(:author, :reviews, :likes, cover_image_attachment: :blob)
              .where(approval_status: 'approved')
              .order(created_at: :desc)

    render json: BookSummarySerializer.new(@books).serializable_hash
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

  # /api/v1/books/:id/storefront
  def storefront
    @book = Book.includes(:author, :reviews, :likes, cover_image_attachment: :blob)
                .find(params[:id])
    
    if @book.approval_status != 'approved'
      render json: { error: "Book not available" }, status: :not_found
      return
    end
  
    render json: StorefrontBookSerializer.new(@book).serializable_hash
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

  def content
    # Get reading token from Authorization header
    token = request.headers['Authorization']&.split(' ')&.last
    
    unless token
      return render json: { error: 'Reading token required' }, status: :unauthorized
    end
    
    begin
      # Decode and verify token
      payload = JWT.decode(token, ENV['DEVISE_JWT_SECRET_KEY'], true, { algorithm: 'HS256' })[0]
      
      # Check if token is for requested book and not expired
      if payload['book_id'] != params[:id] || Time.at(payload['exp']) < Time.current
        return render json: { error: 'Invalid or expired token' }, status: :forbidden
      end   
      
      # Serve different content based on type
      book = Book.find(params[:id])
      
      unless current_reader&.trial_active? || current_reader&.owns_book?(book)
        return render json: { error: 'Access denied. Please purchase this book or use your free trial.' }, status: :payment_required
      end
      
      content_type = payload['content_type']
      
      if content_type == 'ebook'
        # For ebooks: Return file URL or relevant data
        if book.ebook_file.attached?
          # Generate a temporary URL for the file
          url = Rails.application.routes.url_helpers.rails_blob_url(book.ebook_file, only_path: false)
          
          render json: {
            title: book.title,
            url: url,
            format: book.ebook_file.content_type || "application/pdf"
          }
        else
          render json: {
            title: book.title,
            error: "Book content not available",
            format: "unknown"
          }, status: :not_found
        end
      else
        # For audiobooks: Return streaming URL or file URLs
        if book.audiobook_file.attached?
          url = Rails.application.routes.url_helpers.rails_blob_url(book.audiobook_file, only_path: false)
          
          render json: {
            title: book.title,
            audio_files: [url],
            duration: book.respond_to?(:audio_duration) ? book.audio_duration : 0
          }
        else
          render json: {
            title: book.title,
            error: "Audiobook content not available",
            audio_files: []
          }, status: :not_found
        end
      end
    rescue JWT::DecodeError
      render json: { error: 'Invalid reading token' }, status: :unauthorized
    rescue StandardError => e
      Rails.logger.error "Error serving book content: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { error: 'Error retrieving book content' }, status: :internal_server_error
    end
  end 

  # def categories
  #   all_categories = Book.where(approval_status: 'approved').pluck(:categories).compact
  #   category_objects = all_categories.flatten
  #   mains = category_objects.map { |cat| cat["main"]&.strip }.compact.uniq.sort
  #   render json: { categories: mains.map { |name| { name: name } } }
  # end

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

  def audio_url(file)
    # Replace with appropriate URL generation for your storage solution
    # For ActiveStorage:
    # Rails.application.routes.url_helpers.rails_blob_url(file, only_path: false)
    # For simple paths:
    "/storage/audiobooks/#{File.basename(file)}"
  end

  def normalize_json_arrays
    %i[contributors categories keywords tags].each do |field|
      if params[:book][field].is_a?(String)
        begin
          params[:book][field] = JSON.parse(params[:book][field])
        rescue JSON::ParserError
          Rails.logger.warn("Failed to parse JSON for #{field}")
          params[:book][field] = []
        end
      end
    end
  end

  def convert_price_to_cents
    return unless params[:book][:ebook_price].present?
    
    begin
      # Convert from decimal dollars to integer cents
      dollars = BigDecimal(params[:book][:ebook_price])
      params[:book][:ebook_price] = (dollars * 100).round
      Rails.logger.info "Converted price: $#{dollars} → #{params[:book][:ebook_price]} cents"
    rescue ArgumentError => e
      Rails.logger.warn "Failed to convert price: #{e.message}"
    end
  end

  def book_params
    params.require(:book).permit(
      :title, :description, :edition_number, :primary_audience, 
      :publishing_rights, :ebook_price, :audiobook_price, 
      :cover_image, :audiobook_file, :ebook_file, :ai_generated_image, 
      :explicit_images, :subtitle, :bio, :book_isbn, 
      :terms_and_conditions, :publisher, :first_name, :last_name,
      { contributors: [:role, :firstName, :lastName] },
      { categories: [:main, :sub, :detail] },
      keywords: [], tags: []
    )
  end
end
