class Api::V1::PurchasesController < ApplicationController
  before_action :authenticate_reader!
  before_action :set_book, only: [:create]

  def create
    # Check if reader already owns this book
    existing_purchase = current_reader.purchases.find_by(
      book: @book, 
      purchase_status: 'completed'
    )
    
    if existing_purchase
      return render json: {
        status: { code: 422, message: 'You already own this book' }
      }, status: :unprocessable_entity
    end

    # Determine content type and price
    content_type = params[:content_type] || 'ebook'
    amount = content_type == 'ebook' ? @book.ebook_price : @book.audiobook_price

    # Validate that the book has the requested content type available
    unless book_has_content_type?(content_type)
      return render json: {
        status: { code: 422, message: "#{content_type.capitalize} not available for this book" }
      }, status: :unprocessable_entity
    end

    # Initialize payment
    paystack = PaystackService.new
    result = paystack.initialize_transaction(
      email: current_reader.email,
      amount: amount,
      metadata: {
        book_id: @book.id,
        reader_id: current_reader.id,
        content_type: content_type,
        book_title: @book.title
      },
      callback_url: "#{ENV.fetch('FRONTEND_URL', nil)}/payment/callback"
    )

    if result[:success]
      # Create purchase record
      purchase = current_reader.purchases.create!(
        book: @book,
        amount: amount,
        content_type: content_type,
        purchase_status: 'pending',
        purchase_date: Time.current,
        transaction_reference: result[:data]['reference']
      )

      render json: {
        status: { code: 200, message: 'Payment initialized successfully' },
        data: {
          authorization_url: result[:data]['authorization_url'],
          access_code: result[:data]['access_code'],
          reference: result[:data]['reference'],
          purchase_id: purchase.id,
          amount: amount,
          content_type: content_type
        }
      }
    else
      render json: {
        status: { code: 422, message: result[:error] }
      }, status: :unprocessable_entity
    end
  end

  # Verify payment after Paystack callback
  def verify
    reference = params[:reference]
    
    unless reference.present?
      return render json: {
        status: { code: 422, message: 'Payment reference is required' }
      }, status: :unprocessable_entity
    end
  
    # Find the purchase record
    purchase = current_reader.purchases.find_by(transaction_reference: reference)
    unless purchase
      return render json: {
        status: { code: 404, message: 'Purchase record not found' }
      }, status: :not_found
    end
  
    # Verify with Paystack
    paystack = PaystackService.new
    result = paystack.verify_transaction(reference)
  
    if result[:success] && result[:data]['status'] == 'success'
      # AMOUNT VERIFICATION ONLY
      paystack_amount = result[:data]['amount'].to_f
      expected_amount = purchase.amount.to_f
      
      unless paystack_amount == expected_amount
        Rails.logger.error "Amount mismatch: Expected #{expected_amount}, got #{paystack_amount}"
        
        purchase.update!(purchase_status: 'failed')
        
        return render json: {
          status: { code: 422, message: 'Payment amount verification failed' }
        }, status: :unprocessable_entity
      end
      
      # Update purchase status
      purchase.update!(
        purchase_status: 'completed',
        payment_verified_at: Time.current
      )
      
      render json: {
        status: { code: 200, message: 'Payment verified successfully' },
        data: {
          purchase_id: purchase.id,
          book_title: purchase.book.title,
          amount: purchase.amount,
          content_type: purchase.content_type,
          read_link: generate_read_link(purchase)
        }
      }
    else
      # Mark as failed
      purchase.update!(purchase_status: 'failed')
      
      render json: {
        status: { code: 422, message: 'Payment verification failed' }
      }, status: :unprocessable_entity
    end
  end

  # Get user's purchase history
  def index
    purchases = current_reader.purchases.includes(:book)
                             .where(purchase_status: 'completed')
                             .order(created_at: :desc)
    
    render json: {
      status: { code: 200 },
      data: purchases.map do |purchase|
        {
          id: purchase.id,
          book: {
            id: purchase.book.id,
            title: purchase.book.title,
            author: purchase.book.author&.full_name
          },
          content_type: purchase.content_type,
          amount: purchase.amount,
          purchase_date: purchase.purchase_date,
          read_link: generate_read_link(purchase)
        }
      end
    }
  end

  private

  def authenticate_reader!
    token = request.headers['Authorization']&.split(' ')&.last
    
    Rails.logger.info "Authorization header: #{request.headers['Authorization']}"
    Rails.logger.info "Extracted token: #{token&.truncate(50)}"
    
    unless token
      Rails.logger.error "No token provided"
      return render json: {
        status: { code: 401, message: 'Authentication token required' }
      }, status: :unauthorized
    end
  
    begin
      Rails.logger.info "JWT Secret exists: #{ENV['DEVISE_JWT_SECRET_KEY'].present?}"
      
      decoded_token = JWT.decode(
        token, 
        ENV['DEVISE_JWT_SECRET_KEY'],
        true, 
        { algorithm: 'HS256' }
      )
      
      Rails.logger.info "Decoded token payload: #{decoded_token[0]}"
      
      reader_id = decoded_token[0]['sub']
      @current_reader = Reader.find(reader_id)
      
      Rails.logger.info "Authenticated reader: #{@current_reader.email}"
      
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      render json: {
        status: { code: 401, message: 'Invalid authentication token' }
      }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "Reader not found: #{e.message}"
      render json: {
        status: { code: 401, message: 'Reader not found' }
      }, status: :unauthorized
    end
  end

  def current_reader
    @current_reader
  end

  def set_book
    @book = Book.find(params[:book_id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: { code: 404, message: 'Book not found' }
      }, status: :not_found
  end

  def book_has_content_type?(content_type)
    case content_type
    when 'ebook'
      @book.ebook_price.present? && @book.ebook_price > 0
    when 'audiobook'
      @book.audiobook_price.present? && @book.audiobook_price > 0
    else
      false
    end
  end

  def generate_secure_token(purchase)
    JWT.encode(
      { 
        purchase_id: purchase.id, 
        reader_id: purchase.reader_id,
        content_type: purchase.content_type,
        exp: 1.hour.from_now.to_i 
      },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end

  def generate_read_link(purchase)
    token = generate_secure_token(purchase)
    "#{ENV.fetch('API_BASE_URL', 'http://localhost:3000')}/api/v1/reader/#{purchase.id}?token=#{token}"
  end
end