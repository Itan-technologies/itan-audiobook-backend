class Api::V1::Author::BankingDetailsController < ApplicationController
  before_action :authenticate_author!

  def show
    banking_detail = current_author.author_banking_detail
  
    # Find the latest batch_id for this author (if any)
    latest_batch_id = AuthorRevenue.where(author_id: current_author.id)
                                   .where.not(payment_batch_id: nil)
                                   .order(paid_at: :desc)
                                   .limit(1)
                                   .pluck(:payment_batch_id)
                                   .first
  
    render json: (banking_detail ? banking_detail.as_json.merge(batch_id: latest_batch_id) : {})
  end

  def update
    banking_detail = current_author.author_banking_detail || current_author.build_author_banking_detail
    
    if banking_detail.update(banking_detail_params)
      render json: banking_detail, status: :ok
    else
      render json: { errors: banking_detail.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def verify
    banking_detail = current_author.author_banking_detail
    
    if !banking_detail
      render json: { error: "Banking details not found" }, status: :not_found
      return
    end
    
    if banking_detail.verify_account!
      render json: { 
        success: true,
        account_name: banking_detail.resolved_account_name,
        message: "Account verified successfully"
      }
    else
      render json: { 
        success: false, 
        errors: banking_detail.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def banks
    Rails.logger.info "Fetching banks from Paystack..."
    response = PaystackService.list_banks
    
    Rails.logger.info "Banks response: #{response.inspect}"
    
    if response["status"] == true && response["data"].present?
      render json: { banks: response["data"] }
    else
      error_message = response["message"] || "Could not fetch banks"
      Rails.logger.error "Failed to fetch banks: #{error_message}"
      render json: { 
        error: error_message,
        banks: []
      }, status: :service_unavailable
    end
  end
  
  private
  
  def banking_detail_params
    params.require(:banking_detail).permit(:bank_name, :account_number, :account_name, 
                                          :bank_code, :swift_code, :routing_number, :currency)
  end

  def authenticate_author!
    unless current_author
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
  end
end