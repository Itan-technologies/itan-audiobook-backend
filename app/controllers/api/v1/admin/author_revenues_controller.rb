class Api::V1::Admin::AuthorRevenuesController < ApplicationController
  before_action :authenticate_admin!

  # GET /api/v1/admin/author_revenues
  def index
    # Step 1: Check if the basic query returns results
    pending_data = AuthorRevenue.where(status: 'pending')
        
    # Step 2: Check if the grouped query returns results
    grouped_data = AuthorRevenue.where(status: 'pending')
                              .group(:author_id)
                              .select('author_id, SUM(amount) as total_amount, COUNT(*) as pending_count')
        
    # Step 3: Check what happens when we add includes
    with_includes = grouped_data.includes(:author)
      
    # Step 4: Try with pagination
    @pending_by_author = with_includes.page(params[:page]).per(20)
        
    # Continue with your existing render code
    render json: {
      pending_by_author: @pending_by_author.map { |record|
        author = Author.find(record.author_id)        
        {
          author_id: record.author_id,
          author_first_name: author.first_name,
          author_last_name: author.last_name,
          email: author.email,
          total_pending_amount: record.total_amount,
          pending_count: record.pending_count
        }
      },
      pagination: {
        total_pages: @pending_by_author.total_pages,
        current_page: @pending_by_author.current_page,
        total_count: @pending_by_author.total_count
      }
    }
  end

  # Add this action to your Api::V1::Admin::AuthorRevenuesController
  def processed_batches
    processed_batches = AuthorRevenue.where(status: 'approved')
                                     .group(:payment_batch_id)
                                     .select('payment_batch_id, SUM(amount) as total_amount, COUNT(*) as items_count, MIN(paid_at) as approved_date')
                                     .order('approved_date DESC')
                                     .page(params[:page]).per(20)
  
    render json: {
      processed_batches: processed_batches.map { |batch|
        # Get all unique authors for this batch
        authors = Author.joins(:author_revenues)
                        .where(author_revenues: { payment_batch_id: batch.payment_batch_id })
                        .distinct
  
        {
          batch_id: batch.payment_batch_id,
          total_amount: batch.total_amount,
          items_count: batch.items_count,
          approved_date: batch.approved_date&.iso8601,
          authors: authors.map { |a| { id: a.id, name: "#{a.first_name} #{a.last_name}", email: a.email } }
        }
      },
      pagination: {
        total_pages: processed_batches.total_pages,
        current_page: processed_batches.current_page,
        total_count: processed_batches.total_count
      }
    }
  end

  # GET /api/v1/admin/author_revenues/:author_id
  def show
    @author = Author.find(params[:id])
    @pending_revenues = AuthorRevenue.pending
                                    .where(author_id: params[:id])
                                    .includes(purchase: :book)
                                    .page(params[:page]).per(20)
    
    render json: {
      author: {
        id: @author.id,
        name: "#{@author.first_name} #{@author.last_name}",
        email: @author.email
      },
      pending_revenues: @pending_revenues.map { |rev|
        purchase = rev.purchase
        book = purchase&.book
        
        {
          id: rev.id,
          amount: rev.amount,
          status: rev.status,
          created_at: rev.created_at,
          book: {
            id: book&.id,
            title: book&.title || "Unknown Book",
            author_name: book&.author ? "#{book.author.first_name} #{book.author.last_name}" : "#{@author.first_name} #{@author.last_name}",
            # cover_url: book.respond_to?(:cover_url) ? book.cover_url : nil
          },
          purchase: {
            id: purchase&.id,
            content_type: purchase&.content_type,
            purchase_date: purchase&.created_at,
            price: purchase&.amount
          },
          file_size_mb: calculate_file_size(purchase)
        }
      },
      pagination: {
        total_pages: @pending_revenues.total_pages,
        current_page: @pending_revenues.current_page,
        total_count: @pending_revenues.total_count
      }
    }
  end
  
  def process_payments
      # Only allow processing in the last 3 days of the month
    unless Date.today >= Date.today.end_of_month - 2.days
      render json: { 
        error: "Payments can only be processed during the last 3 days of the month (#{(Date.today.end_of_month - 2.days).strftime('%B %d')} - #{Date.today.end_of_month.strftime('%B %d')})",
        days_until_processing: (Date.today.end_of_month - 2.days - Date.today).to_i
      }, status: :unprocessable_entity
      return
    end

    author_ids = params[:author_ids] || []
    min_payment_threshold = ENV.fetch('MIN_PAYMENT_THRESHOLD', 5.0).to_f
    processed_authors = []
    skipped_authors = []
    
    if author_ids.empty?
      render json: { error: "No authors selected" }, status: :bad_request
      return
    end
    
    batch_id = "BATCH-#{SecureRandom.hex(8)}"
    
    begin
      AuthorRevenue.transaction do
        # Process each selected author from the parameters
        author_ids.each do |author_id|
          author = Author.find(author_id)
          
          # Get pending revenues for this author
          pending_revenues = AuthorRevenue.where(
            author_id: author_id,
            status: 'pending'
          )
          
          total_amount = pending_revenues.sum(:amount).to_f
          sale_count = pending_revenues.count
          
          # Skip authors below threshold
          if total_amount < min_payment_threshold
            skipped_authors << {
              author_id: author_id,
              amount: total_amount,
              reason: "Below payment threshold"
            }
            next
          end
          
          if pending_revenues.any?
            payment_ref = "PAY-#{SecureRandom.hex(6)}"
            
            pending_revenues.update_all(
              status: 'approved',
              paid_at: Time.current,
              payment_batch_id: batch_id,
              payment_reference: payment_ref,
              notes: "Approved in batch #{batch_id}"
            )
            
            # Add to processed authors AFTER creating the payment_ref
            processed_authors << {
              author_id: author_id,
              amount: total_amount,
              payment_reference: payment_ref,
              batch_id: batch_id
            }
            
            # Send email with correct values
            AuthorMailer.payment_processed(
              author, 
              total_amount,
              sale_count,
              payment_ref
            ).deliver_later
          end
        end
      end
      
      # Return detailed response with both processed and skipped authors
      render json: {
        success: true,
        batch_id: batch_id,
        message: "Payment processing completed",
        processed: {
          count: processed_authors.length,
          authors: processed_authors
        },
        skipped: {
          count: skipped_authors.length,
          authors: skipped_authors
        }
      }
    rescue => e
      Rails.logger.error("Payment processing failed: #{e.message}")
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end

  def transfer_funds
    batch_id = params[:batch_id]
    
    # First check if batch_id exists
    unless batch_id.present?
      render json: { error: "Batch ID required" }, status: :bad_request
      return
    end
    
    # Then check if batch exists
    batch_payments = AuthorRevenue.where(payment_batch_id: batch_id)
    if batch_payments.empty?
      render json: { error: "No payments found with this batch ID" }, status: :not_found
      return
    end
    
    # Check if payments in this batch are ready for transfer
    earliest_approval = batch_payments.minimum(:paid_at)
    
    # if earliest_approval && earliest_approval > 30.days.ago
    #   days_remaining = (earliest_approval + 30.days - Time.current).to_i / 1.day
    #   render json: { 
    #     error: "Payments not yet eligible for transfer", 
    #     eligible_date: (earliest_approval + 30.days).strftime('%Y-%m-%d'),
    #     days_remaining: days_remaining
    #   }, status: :unprocessable_entity
    #   return
    # end
    
    results = TransferProcessor.process_batch(batch_id)
    
    render json: {
      success: true,
      transferred: results[:success],
      failed: results[:failed]
    }
  end

  private

  def calculate_file_size(purchase)
    return 0 unless purchase&.book
    
    case purchase.content_type
    when 'ebook'
      purchase.book.ebook_file&.byte_size.to_f / (1024 * 1024)
    when 'audiobook'
      purchase.book.audio_file&.byte_size.to_f / (1024 * 1024)
    else
      0
    end.round(2)
  end
end