class Api::V1::Author::BankingDetailsController < ApplicationController
  before_action :authenticate_author!

  # GET /api/v1/author/banking_details
  # Returns the banking details for the current author
  # If no banking details are set, returns account_setup: false
  # If banking details exist, returns account_name, masked account_number, bank_code, and verified status
  # app/models/author_banking_detail.rb
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
  
  def show
    banking_detail = current_author.author_banking_detail
    
    if banking_detail
      render json: {
        account_name: banking_detail.account_name,
        account_number: mask_account_number(banking_detail.account_number),
        bank_code: banking_detail.bank_code,
        verified: banking_detail.verified_at.present?
      }
    else
      render json: { account_setup: false }
    end
  end
  
  def update
    paystack_service = PaystackTransferService.new
    
    # First verify the account
    verify_result = paystack_service.verify_account(
      params[:account_number],
      params[:bank_code]
    )
    
    unless verify_result[:success]
      return render json: {
        success: false,
        error: "Account verification failed: #{verify_result[:error]}"
      }, status: :unprocessable_entity
    end
    
    # Get or create banking details
    banking_detail = current_author.author_banking_detail || 
                     current_author.build_author_banking_detail
    
    banking_detail.account_name = verify_result[:data]['account_name']
    banking_detail.account_number = params[:account_number]
    banking_detail.bank_code = params[:bank_code]
    
    if banking_detail.save
      # Create recipient in Paystack
      recipient_result = paystack_service.create_recipient(banking_detail)
      
      if recipient_result[:success]
        banking_detail.update(verified_at: Time.current)
        
        render json: {
          success: true,
          message: "Banking details updated successfully",
          account_name: banking_detail.account_name
        }
      else
        render json: {
          success: false,
          error: "Failed to create transfer recipient: #{recipient_result[:error]}"
        }, status: :unprocessable_entity
      end
    else
      render json: {
        success: false, 
        error: banking_detail.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def mask_account_number(account_number)
    return nil unless account_number.present?
    last_digits = account_number.last(4)
    "XXXX#{last_digits}"
  end
end