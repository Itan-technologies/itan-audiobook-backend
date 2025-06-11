# app/controllers/api/v1/reader_controller.rb (Enhanced Version)
class Api::V1::ReaderController < ApplicationController
  before_action :authenticate_reader_token
  before_action :find_purchase
  before_action :validate_access
  # before_action :track_reading_session  # ← Add this
  # before_action :rate_limit_requests    # ← Add this
  
  # Get book metadata for reader app
  def metadata
    render json: {
      status: { code: 200 },
      data: {
        book_id: @purchase.book.id,
        title: @purchase.book.title,
        author: @purchase.book.first_name,
        content_type: @purchase.content_type,
        total_pages: extract_total_pages,          
        watermark: generate_watermark,
        session_id: SecureRandom.hex(16),                  
        expires_at: @token_data['exp']        
      }
    }
  end
  
  # Get specific page content (enhanced)
  def page
    page_number = params[:page].to_i
    
    unless valid_page?(page_number)                # ← Add validation
      return render json: {
        status: { code: 400, message: 'Invalid page number' }
      }, status: :bad_request
    end
    
    page_content = extract_page_content(page_number)
    
    render json: {
      status: { code: 200 },
      data: {
        page_number: page_number,
        total_pages: extract_total_pages,
        content: page_content,
        watermark: generate_watermark,
        expires_at: 10.minutes.from_now.to_i,     # ← Longer expiration
        session_id: @token_data['exp']
      }
    }
  end
  
  # Add session validation endpoint
  def heartbeat
    render json: {
      status: { code: 200 },
      data: {
        session_valid: true,
        expires_at: @token_data['exp'],
        server_time: Time.current.to_i
      }
    }
  end
  
  private
  
  def authenticate_reader_token
    token = params[:token] || request.headers['Authorization']&.split(' ')&.last
    
    unless token
      return render json: { 
        status: { code: 401, message: 'Access token required' } 
      }, status: :unauthorized
    end
    
    begin
      decoded = JWT.decode(token, ENV['DEVISE_JWT_SECRET_KEY'], true, { algorithm: 'HS256' })
      @token_data = decoded[0]
      
      # Check token expiration
      if @token_data['exp'] < Time.current.to_i
        return render json: {
          status: { code: 401, message: 'Token expired' }
        }, status: :unauthorized
      end
      
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      render json: { 
        status: { code: 401, message: 'Invalid access token' } 
      }, status: :unauthorized
    end
  end
  
  def find_purchase
    @purchase = Purchase.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      status: { code: 404, message: 'Content not found' } 
    }, status: :not_found
  end
  
  def validate_access
    # Enhanced validation
    unless @purchase.purchase_status == 'completed' && 
           @purchase.reader_id.to_s == @token_data['reader_id'] &&
           @purchase.id.to_s == @token_data['purchase_id']
      
      render json: { 
        status: { code: 403, message: 'Access denied' } 
      }, status: :forbidden
    end
  end
  
  # NEW: Add session tracking
  # def track_reading_session
  #   @session_id = SecureRandom.hex(16)
    
  #   # Create reading session record
  #   @reading_session = ReadingSession.create!(
  #     reader: @purchase.reader,
  #     purchase: @purchase,
  #     ip_address: request.remote_ip,
  #     user_agent: request.user_agent,
  #     session_id: @session_id,
  #     accessed_at: Time.current
  #   )
    
  #   # Check for suspicious activity
  #   detect_suspicious_activity
  # end
  
  # NEW: Rate limiting
  # def rate_limit_requests
  #   cache_key = "reader_requests:#{@purchase.reader_id}:#{Time.current.strftime('%Y%m%d%H%M')}"
  #   current_requests = Rails.cache.read(cache_key) || 0
    
  #   if current_requests >= 100  # Max 100 requests per minute
  #     return render json: {
  #       status: { code: 429, message: 'Too many requests. Please slow down.' }
  #     }, status: :too_many_requests
  #   end
    
  #   Rails.cache.write(cache_key, current_requests + 1, expires_in: 1.minute)
  # end
  
  # NEW: Suspicious activity detection
  def detect_suspicious_activity
    recent_sessions = ReadingSession.where(
      purchase: @purchase,
      accessed_at: 30.minutes.ago..Time.current
    )
    
    unique_ips = recent_sessions.distinct.count(:ip_address)
    
    if unique_ips > 3  # Allow max 3 IPs (home + mobile + work)
      SecurityAlert.create!(
        purchase: @purchase,
        alert_type: 'multiple_ip_access',
        details: "Book accessed from #{unique_ips} different IPs in 30 minutes",
        severity: 'medium'
      )
      
      Rails.logger.warn "Suspicious activity detected for purchase #{@purchase.id}"
    end
  end
  
  # ENHANCED: Better page validation
  def valid_page?(page_number)
    page_number > 0 && page_number <= extract_total_pages
  end
  
  # NEW: Get total pages efficiently
  def extract_total_pages
    @total_pages ||= begin
      if @purchase.content_type == 'ebook' && @purchase.book.ebook_file.attached?
        # Cache the page count for performance
        Rails.cache.fetch("book_pages_#{@purchase.book.id}", expires_in: 1.hour) do
          PDFProcessor.count_pages(@purchase.book.ebook_file)
        end
      else
        0
      end
    end
  end
  
  def extract_page_content(page_number)
    file_attachment = @purchase.book.ebook_file
    
    if file_attachment.attached?
      raw_content = PDFProcessor.extract_page(file_attachment, page_number)
      return nil unless raw_content
      
      watermarked_content = add_watermark(raw_content)
      # Return content without encryption for MVP simplicity
      watermarked_content
    else
      nil
    end
  end
  
  def generate_watermark
    "#{@purchase.reader.email} • #{Time.current.strftime('%Y-%m-%d %H:%M')}"
  end
  
  def add_watermark(content)
    watermark = generate_watermark
    
    # Add watermark every few paragraphs
    paragraphs = content.split("\n\n")
    watermarked_paragraphs = []
    
    paragraphs.each_with_index do |paragraph, index|
      watermarked_paragraphs << paragraph
      
      # Add watermark every 5 paragraphs
      if (index + 1) % 5 == 0
        watermarked_paragraphs << "\n[#{watermark}]\n"
      end
    end
    
    watermarked_paragraphs.join("\n\n")
  end
  
  # Keep your existing methods
  def serve_ebook_content
    redirect_to metadata_api_v1_reader_path(@purchase.id, token: params[:token])
  end
end