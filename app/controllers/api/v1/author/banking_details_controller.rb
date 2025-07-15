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
    
    # Set the new banking details
    banking_detail.assign_attributes(banking_detail_params)
    
    # Verify the account before saving
    if banking_detail.verify_account!
      # If verification succeeds, save the details
      if banking_detail.save
        render json: {
          success: true,
          message: "Banking details verified and saved successfully",
          data: banking_detail.as_json.merge(
            account_name: banking_detail.resolved_account_name,
            verified: true,
            verified_at: banking_detail.verified_at
          )
        }, status: :ok
      else
        render json: { 
          success: false,
          errors: banking_detail.errors.full_messages 
        }, status: :unprocessable_entity
      end
    else
      # If verification fails, don't save and return verification errors
      render json: { 
        success: false,
        message: "Account verification failed",
        errors: banking_detail.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # Verify banking details (works with saved details or provided params)
  def verify
    # Use provided params OR fallback to saved banking details
    bank_code = params[:bank_code]
    account_number = params[:account_number]
    
    # If no params provided, use saved banking details
    if bank_code.blank? || account_number.blank?
      banking_detail = current_author.author_banking_detail
      
      if !banking_detail
        render json: { error: "Banking details not found" }, status: :not_found
        return
      end
      
      # Use the verify_account! method on the saved record
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
    else
      # Direct verification with provided params (for real-time validation)
      begin
        Rails.logger.info "Real-time validation: #{account_number}, #{bank_code}"
        response = PaystackService.resolve_account(account_number, bank_code)
        Rails.logger.info "Paystack Response: #{response.inspect}"
        
        if response["status"] == true
          render json: {
            success: true,
            account_name: response["data"]["account_name"],
            message: "Account verified successfully"
          }
        else
          error_message = response["message"] || "Account verification failed"
          render json: {
            success: false,
            error: error_message
          }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Validation error: #{e.message}"
        render json: {
          success: false,
          error: "Verification service error"
        }, status: :internal_server_error
      end
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