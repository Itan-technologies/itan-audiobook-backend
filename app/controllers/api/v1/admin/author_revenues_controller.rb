class Api::V1::Admin::AuthorRevenuesController < ApplicationController
  before_action :authenticate_admin!

  def index
    @pending_revenues = AuthorRevenue.pending.includes(:author, purchase: :book)
    @pending_by_author = AuthorRevenue.pending.group(:author_id).sum(:amount)
    @pending_count = AuthorRevenue.pending.group(:author_id).count
    # @recent_payments = AuthorRevenue.approved.order(paid_at: :desc).limit(50)
    
    render json: {
      pending_by_author: @pending_by_author.map { |author_id, amount| 
        author = Author.find(author_id)
        {
          author_id: author_id,
          author_first_name: author.first_name,
          author_last_name: author.last_name,
          email: author.email,
          total_pending_amount: amount,
          pending_count: @pending_count[author_id],
          detailed_revenues: @pending_revenues.where(author_id: author_id).map { |rev|
          purchase = rev.purchase
          book = purchase.book
          
          # Example calculation (adjust based on your actual logic)
          file_size = case purchase.content_type
                      when 'ebook'
                        book.ebook_file.byte_size.to_f / (1024 * 1024)
                      when 'audiobook'
                        book.audio_file.byte_size.to_f / (1024 * 1024)
                      else
                        0
                      end
          
          {
            id: rev.id,
            amount: rev.amount,
            book_title: book.title,
            book_price: book.ebook_price,
            purchase_date: rev.created_at,
            content_type: purchase.content_type,
            file_size_mb: file_size.round(2)  # Round to 2 decimal places
          }
        }
                }
      },
      # recent_payments: @recent_payments
    }
  end
  
  def process_payments
    author_ids = params[:author_ids] || []
    
    if author_ids.empty?
      render json: { error: "No authors selected" }, status: :bad_request
      return
    end
    
    batch_id = "BATCH-#{SecureRandom.hex(8)}"
    
    begin
      AuthorRevenue.transaction do
        author_ids.each do |author_id|
          author = Author.find(author_id)
          
          # Get pending revenues for this author
          pending_revenues = AuthorRevenue.where(
            author_id: author_id,
            status: 'pending'
          )
          
          total_amount = pending_revenues.sum(:amount).to_f
          sale_count = pending_revenues.count
          
          if pending_revenues.any?
            payment_ref = "PAY-#{SecureRandom.hex(6)}"
            
            pending_revenues.update_all(
              status: 'approved',
              paid_at: Time.current,
              payment_batch_id: batch_id,
              payment_reference: payment_ref,
              notes: "Approved in batch #{batch_id}"
            )
            
            # Send email with correct values
            AuthorMailer.payment_processed(
              author, 
              total_amount,
              sale_count
            ).deliver_later
          end
        end
      end
      
      render json: { success: true, message: "Payments processed successfully" }
    rescue => e
      Rails.logger.error("Payment processing failed: #{e.message}")
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
end