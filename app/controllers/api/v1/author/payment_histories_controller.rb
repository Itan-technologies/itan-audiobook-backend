class Api::V1::Author::PaymentHistoriesController < ApplicationController
  before_action :authenticate_author!
  
    def index
      payments_data = current_author.author_revenues
                              .where(status: 'approved')
                              .group(:payment_batch_id)
                              .select('payment_batch_id, SUM(amount) as total_amount, MIN(paid_at) as payment_date')
                              .order('payment_date DESC')
                              
        # Transform for proper JSON serialization
        formatted_payments = payments_data.map do |payment|
        {          
          batch_id: payment.payment_batch_id,
          total_amount: payment.total_amount,
          payment_date: payment.payment_date&.iso8601,  # Format date properly
          items_count: current_author.author_revenues.where(payment_batch_id: payment.payment_batch_id).count
        }
        end
                              
        render json: { payments: formatted_payments }
    end
    
    def show
      @payment_details = current_author.author_revenues
                                     .where(payment_batch_id: params[:id])
                                     .includes(purchase: :book)
                                     
      render json: { payment_details: @payment_details }
    end
  end