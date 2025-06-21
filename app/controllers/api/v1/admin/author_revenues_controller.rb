class Api::V1::Admin::AuthorRevenuesController < ApplicationController
  before_action :authenticate_admin!

  def index
    @pending_revenues = AuthorRevenue.pending.includes(:author, purchase: :book)
    @pending_by_author = AuthorRevenue.pending.group(:author_id).sum(:amount)
    @pending_count = AuthorRevenue.pending.group(:author_id).count
    @recent_payments = AuthorRevenue.approved.order(paid_at: :desc).limit(50)
    
    render json: {
      pending_by_author: @pending_by_author.map { |author_id, amount| 
        author = Author.find(author_id)
        {
          author_id: author_id,
          author_first_name: author.first_name,
          author_last_name: author.last_name,
          email: author.email,
          pending_amount: amount,
          pending_count: @pending_count[author_id],
          detailed_revenues: @pending_revenues.where(author_id: author_id).map { |rev|
        {
          id: rev.id,
          amount: rev.amount,
          book_title: rev.purchase.book.title,
          purchase_date: rev.created_at,
          content_type: rev.purchase.content_type
        }
      }
        }
      },
      recent_payments: @recent_payments
    }
  end
  
  def process_payments
    author_ids = params[:author_ids]
    batch_id = "BATCH-#{SecureRandom.hex(8)}"
    payment_date = Time.current
    
    # Find all pending revenues for these authors
    pending_revenues = AuthorRevenue.where(author_id: author_ids, status: 'pending')
    
    # Calculate totals for the response
    payment_summary = pending_revenues.group(:author_id).sum(:amount)
    
    # Process each author's payment
    authors_processed = 0
    revenues_processed = 0
    
    begin
      ActiveRecord::Base.transaction do
        author_ids.each do |author_id|
          author = Author.find(author_id)
          author_revenues = pending_revenues.where(author_id: author_id)
          total_amount = author_revenues.sum(:amount)
          
          # In a real system, you'd make an API call to your payment processor here
          # payment_result = PaymentGateway.transfer_funds(author.payment_details, total_amount)
          payment_reference = "PAY-#{SecureRandom.hex(6)}"
          
          # Update all revenue records for this author
          updated_count = author_revenues.update_all(
            status: 'approved',
            paid_at: payment_date,
            payment_batch_id: batch_id,
            payment_reference: payment_reference,
            notes: "Approved in batch #{batch_id}"
          )
          
        # Send email notification instead of creating a notification record
        AuthorMailer.payment_processed(author, total_amount, updated_count).deliver_later
          
          authors_processed += 1
          revenues_processed += updated_count
        end
      end
      
      render json: {
        success: true,
        message: "Processed payments for #{authors_processed} authors (#{revenues_processed} sales)",
        batch_id: batch_id,
        payment_date: payment_date,
        payments: payment_summary.map { |author_id, amount| {
          author_id: author_id,
          amount: amount
        }}
      }
    rescue => e
      render json: {
        success: false,
        error: "Payment processing failed: #{e.message}"
      }, status: :unprocessable_entity
    end
  end
end