class Api::V1::Admin::BooksController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_book, only: %i[show approve reject]

  # GET /api/v1/admin/books
  def index
    @books = Book.includes(:author, cover_image_attachment: :blob)
      .order(created_at: :desc)

    @books = case params[:status]
             when 'pending' then @books.pending
             when 'approved' then @books.approved
             when 'rejected' then @books.rejected
             else @books
             end

    render_books_json(@books)
  end

  # GET /api/v1/admin/books/:id
  def show
    render_books_json(@book)
  end

  # PATCH /api/v1/admin/books/:id/approve
  def approve
    if params[:admin_feedback].blank?
      return render json: {
        status: { code: 422, message: 'Admin feedback is required when approving a book' }
      }, status: :unprocessable_entity
    end

    # Process data consistently
    process_book_attributes

    # Include feedback in the update if needed
    if @book.update(
      approval_status: 'approved',
      admin_feedback: params[:admin_feedback]
    )
      render_books_json(@book, 'Book approved successfully.')
    else
      render json: {
        status: { code: 422, message: @book.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/admin/books/:id/reject
  def reject
    # Validate presence of admin_feedback
    if params[:admin_feedback].blank?
      return render json: {
        status: { code: 422, message: 'Admin feedback is required when rejecting a book' }
      }, status: :unprocessable_entity
    end

    # Process data consistently
    process_book_attributes

    # Now perform the update
    if @book.update(
      approval_status: 'rejected',
      admin_feedback: params[:admin_feedback]
    )
      render json: {
        status: { code: 200, message: 'Book rejected.' },
        data: BookSerializer.new(@book).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: { code: 422, message: @book.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: { code: 404, message: 'Book not found' }
    }, status: :not_found
  end

  def render_books_json(books, message = nil, status_code = 200)
    response = {
      status: { code: status_code }
    }

    response[:status][:message] = message if message

    response[:data] = if books.is_a?(Book)
                        BookSerializer.new(books).serializable_hash[:data][:attributes]
                      else
                        BookSerializer.new(books).serializable_hash[:data].map { |book| book[:attributes] }
                      end

    render json: response
  end

  def process_book_attributes
    # Handle keywords and tags conversion
    @book.keywords = @book.keywords.split(',').map(&:strip) if @book.keywords.present? && !@book.keywords.is_a?(Array)

    return unless @book.tags.present? && !@book.tags.is_a?(Array)

    @book.tags = @book.tags.split(',').map(&:strip)
  end

  def authenticate_admin!
    return if current_admin

    render json: { error: 'Unauthorized' }, status: :unauthorized
    nil
  end
end
