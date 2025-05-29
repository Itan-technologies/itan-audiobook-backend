# app/controllers/api/v1/reader_controller.rb
class Api::V1::ReaderController < ApplicationController
    before_action :authenticate_reader_token
    before_action :find_purchase
    before_action :validate_access
    
    # This Streamed book content for in-app reading
    def show
      case @purchase.content_type
      when 'ebook'
        serve_ebook_content
      when 'audiobook'
        serve_audiobook_stream
      end
    end
    
    # Get book metadata for reader app
    def metadata
      render json: {
        status: { code: 200 },
        data: {
          book_id: @purchase.book.id,
          title: @purchase.book.title,
          author: @purchase.book.author&.first_name,
          content_type: @purchase.content_type,
          total_pages: @purchase.book.total_pages,
          # duration: @purchase.book.duration, # for audiobooks
          watermark: generate_watermark
        }
      }
    end
    
    # Get specific page/chapter (for ebooks)
    def page
      page_number = params[:page].to_i
      
      # Extract specific page from PDF/EPUB
      page_content = extract_page_content(page_number)
      
      render json: {
        status: { code: 200 },
        data: {
          page_number: page_number,
          content: page_content,
          watermark: generate_watermark,
          expires_at: 5.minutes.from_now
        }
      }
    end
    
    # Stream audio chunks (for audiobooks)
    # def audio_chunk
    #   start_time = params[:start].to_f
    #   duration = params[:duration].to_f || 30.0 # 30-second chunks
      
    #   # Generate time-limited audio chunk
    #   audio_data = extract_audio_chunk(start_time, duration)
      
    #   response.headers['Content-Type'] = 'audio/mpeg'
    #   response.headers['Content-Disposition'] = 'inline'
    #   response.headers['Cache-Control'] = 'no-store, must-revalidate'
      
    #   render body: audio_data
    # end
    
    private
    
    def authenticate_reader_token
      token = params[:token]
      
      unless token
        return render json: { 
          status: { code: 401, message: 'Access token required' } 
        }, status: :unauthorized
      end
      
      begin
        # Use only DEVISE_JWT_SECRET_KEY for consistency
        decoded = JWT.decode(token, ENV['DEVISE_JWT_SECRET_KEY'], true, { algorithm: 'HS256' })
        @token_data = decoded[0]
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
      unless @purchase.completed? && 
             @purchase.reader_id == @token_data['reader_id'] &&
             @purchase.id == @token_data['purchase_id']
        
        render json: { 
          status: { code: 403, message: 'Access denied' } 
        }, status: :forbidden
      end
    end
    
    def serve_ebook_content
      # Instead of direct download, serve content for in-app reader
      redirect_to metadata_api_v1_reader_path(@purchase.id, token: params[:token])
    end
    
    # def serve_audiobook_stream
    #   # Redirect to streaming metadata
    #   redirect_to metadata_api_v1_reader_path(@purchase.id, token: params[:token])
    # end
    
    def extract_page_content(page_number)
      # Use gems like PDF-Reader or Yomu to extract specific pages
      # Return encrypted/watermarked content
      file_attachment = @purchase.book.ebook_file
      
      # This is pseudocode - implement based on your file format
      if file_attachment.attached?
        # Extract page content with watermarking
        raw_content = PDFProcessor.extract_page(file_attachment, page_number)
        watermarked_content = add_watermark(raw_content)
        encrypt_content(watermarked_content)
      else
        nil
      end
    end
    
    # def extract_audio_chunk(start_time, duration)
    #   # Use FFmpeg or similar to extract audio chunks
    #   file_attachment = @purchase.book.audiobook_file
      
    #   if file_attachment.attached?
    #     # Extract time-based chunk and add audio watermark
    #     AudioProcessor.extract_chunk(file_attachment, start_time, duration)
    #   else
    #     nil
    #   end
    # end
    
    def generate_watermark
      "#{@purchase.reader.email} - #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    end
    
    def add_watermark(content)
      # Add reader info as watermark to prevent sharing
      watermark = generate_watermark
      ContentProcessor.add_watermark(content, watermark)
    end
    
    def encrypt_content(content)
      # Encrypt content that can only be decrypted by your frontend
      key = Rails.application.credentials.content_encryption_key
      EncryptionService.encrypt(content, key)
    end
  end