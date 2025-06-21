class Api::V1::Author::PaymentHistoriesController < ApplicationController
  before_action :authenticate_author!
  
    def index
      @payments = current_author.author_revenues
                               .where(status: 'paid')
                               .group(:payment_batch_id)
                               .select('payment_batch_id, SUM(amount) as total_amount, MIN(paid_at) as payment_date')
                               .order('payment_date DESC')
                               
      render json: { payments: @payments }
    end
    
    def show
      @payment_details = current_author.author_revenues
                                     .where(payment_batch_id: params[:id])
                                     .includes(purchase: :book)
                                     
      render json: { payment_details: @payment_details }
    end
  end