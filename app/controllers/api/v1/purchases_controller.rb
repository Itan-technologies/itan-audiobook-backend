class Api::V1::PurchasesController < ApplicationController
  before_action :authenticate_reader!
  skip_before_action :authenticate_reader!, only: [:verify]
  # skip_before_action :verify_authenticity_token, only: [:verify]
  before_action :set_book, only: [:create]

  def create
    service = PurchaseService.new(current_reader, @book, params[:content_type])
    result = service.create_purchase
    
    if result[:success]
      render json: {
        status: { code: 200, message: 'Purchase created successfully' },
        data: result[:data]
      }
    else
      render json: {
        status: { code: 422, message: result[:error] }
      }, status: :unprocessable_entity
    end
  end

  # Verify payment after Paystack callback
  def verify
    Rails.logger.info "============ PAYSTACK WEBHOOK RECEIVED ============"
  
    # Extract reference from the correct location
    reference = params[:data][:reference]
    
    # 1. CRITICAL: Verify webhook signature first
    unless verify_webhook_signature      
      return render json: { 
        status: { code: 401, message: 'Unauthorized webhook' } 
      }, status: :unauthorized
    end
    
    # 2. Find purchase directly without using current_reader
    purchase = Purchase.find_by(transaction_reference: reference)
    
    if purchase.nil?      
      return render json: {
        status: { code: 404, message: 'Purchase not found' }
      }, status: :not_found
    end
    
    # 3. Update purchase status directly - IMPORTANT: No validation checks
    if purchase.update(purchase_status: 'completed')      
      RevenueCalculationService.new(purchase).calculate
      render json: {
        status: { code: 200, message: 'Payment verified successfully' },
        data: { purchase_id: purchase.id }
      }
    else
      Rails.logger.error "❌ Failed to update purchase: #{purchase.errors.full_messages.join(', ')}"
      render json: {
        status: { code: 422, message: 'Failed to update purchase status' }
      }, status: :unprocessable_entity
    end
    
    rescue StandardError => e
      Rails.logger.error "Payment verification error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        status: { code: 500, message: 'Internal server error' }
      }, status: :internal_server_error
  end
  
  # Get user's purchase history
  def index
    purchases = current_reader.purchases.includes(book: { cover_image_attachment: :blob })
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
            author_first_name: purchase.book.first_name,
            cover_image_url: (
              Rails.application.routes.url_helpers.url_for(purchase.book.cover_image) if purchase.book.cover_image.attached?
            )
          },
          content_type: purchase.content_type,
          amount: purchase.amount,
          purchase_date: purchase.purchase_date,
          reading_token: generate_reading_token(purchase)
        }
      end
    }
  end

  def check_status
    reference = params[:reference]
    purchase = Purchase.find_by(transaction_reference: reference)
    
    if purchase.nil?
      return render json: {
        status: { code: 404, message: 'Purchase not found' }
      }, status: :not_found
    end
    
    # If purchase is completed, include reading token
    reading_token = nil
    if purchase.purchase_status == 'completed'
      reading_token = generate_reading_token(purchase)
    end
    
    render json: {
      status: { code: 200 },
      data: {
        purchase_id: purchase.id,
        purchase_status: purchase.purchase_status,
        book_id: purchase.book.id,
        book_title: purchase.book.title,
        content_type: purchase.content_type,
        purchase_date: purchase.purchase_date,
        reading_token: reading_token
      }
    }
  end

  def refresh_reading_token
    purchase_id = params[:purchase_id]
    
    unless purchase_id
      return render json: { 
        status: { code: 400, message: 'Purchase ID is required' } 
      }, status: :bad_request
    end
    
    begin
      purchase = current_reader.purchases.find(purchase_id)
      
      if purchase.purchase_status == 'completed'
        render json: {
          status: { code: 200 },
          data: {
            reading_token: generate_reading_token(purchase)
          }
        }
      else
        render json: {
          status: { code: 403, message: 'Access denied' }
        }, status: :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: { code: 404, message: 'Purchase not found' }
      }, status: :not_found
    end
  end

  private

  def authenticate_reader!
    token = request.headers['Authorization']&.split(' ')&.last
    
    unless token
      Rails.logger.error "No token provided"
      return render json: {
        status: { code: 401, message: 'Authentication token required' }
      }, status: :unauthorized
    end
  
    begin
        
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

  def generate_reading_token(purchase)
    JWT.encode(
      { 
        sub: purchase.reader_id,           # Reader ID as subject
        purchase_id: purchase.id,
        content_type: purchase.content_type,
        book_id: purchase.book.id,
        exp: 4.hours.from_now.to_i        # 4 hours reading session
      },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end
 
  # Enhanced webhook signature verification with development bypass
  def verify_webhook_signature
    # DEVELOPMENT BYPASSED
    # if Rails.env.development? && (params[:skip_verification] == 'true' || request.headers['X-Skip-Verification'] == 'true')
    #   Rails.logger.warn "⚠️ BYPASSING webhook signature verification in development!"
    #   Rails.logger.warn "⚠️ DO NOT USE THIS IN PRODUCTION!"
    #   return true
    # end
  
    payload = request.raw_post
    signature = request.headers['HTTP_X_PAYSTACK_SIGNATURE']
    
    # Add debug logging
    Rails.logger.debug "Webhook received for verification"
    
    return false unless signature.present? && payload.present?
    
    webhook_secret = ENV['PAYSTACK_SECRET_KEY']
    expected = OpenSSL::HMAC.hexdigest('sha512', webhook_secret, payload)
    
    result = ActiveSupport::SecurityUtils.secure_compare(signature, expected)
    
    if result
      Rails.logger.info "✅ Webhook signature verified successfully"
    else
      Rails.logger.error "❌ Webhook signature verification failed"
      Rails.logger.debug "Expected: #{expected[0..10]}..." if expected
      Rails.logger.debug "Received: #{signature[0..10]}..." if signature
    end
    
    result
  end

# Map status codes to HTTP symbols
  def map_http_status_code(code)
    case code
    when 409 then :conflict
    when 402 then :payment_required
    when 502 then :bad_gateway
    else :unprocessable_entity
    end
  end

# Updated signature verification method (fix your existing one)
  # def verify_paystack_signature(payload, signature)
  #   return false unless signature.present? && payload.present?

  #   # Use webhook secret, fallback to secret key for MVP
  #   webhook_secret = ENV['PAYSTACK_WEBHOOK_SECRET'] || ENV['PAYSTACK_SECRET_KEY']
  #   expected = OpenSSL::HMAC.hexdigest('sha512', webhook_secret, payload)

  #   ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  # end
end