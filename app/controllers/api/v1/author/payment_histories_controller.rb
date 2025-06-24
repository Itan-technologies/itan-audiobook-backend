class Api::V1::Author::PaymentHistoriesController < ApplicationController
  before_action :authenticate_author!
  
    # app/controllers/api/v1/author/payment_histories_controller.rb
    def index
      payments_data = current_author.author_revenues
                              .where(status: ['approved', 'transferred'])
                              .group(:payment_batch_id)
                              .select('payment_batch_id, SUM(amount) as total_amount, MIN(paid_at) as payment_date, MIN(status) as status, MIN(transfer_reference) as transfer_reference')
                              .order('payment_date DESC')
                          
      formatted_payments = payments_data.map do |payment|
        items = current_author.author_revenues.where(payment_batch_id: payment.payment_batch_id)
        status_message = payment.status == 'transferred' ? 'Transferred to bank account' : 'Approved and pending transfer'
        
        # Calculate estimated deposit date using 30 day policy
        if payment.payment_date
          estimated_date = payment.payment_date + 30.days
          estimated_date_formatted = estimated_date.iso8601
        else
          estimated_date_formatted = nil
        end
        
        {          
          batch_id: payment.payment_batch_id,
          total_amount: payment.total_amount,
          approved_date: payment.payment_date&.iso8601,
          transfer_reference: payment.transfer_reference,
          status: payment.status,
          status_message: status_message,
          estimated_deposit_date: estimated_date_formatted,
          items_count: items.count
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