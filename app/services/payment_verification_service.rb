class PaymentVerificationService
  class VerificationError < StandardError; end
  
  def initialize(reference, current_reader = nil)
    @reference = reference
    @current_reader = current_reader
  end
  
  def verify
    validate_reference!
    find_purchase!
    
    # Early return for already verified payments
    return { success: true, data: build_success_response } if already_verified?
    
    validate_purchase_state!
    verify_with_provider!
    
    { success: true, data: build_success_response }
  rescue VerificationError => e
    { success: false, error: e.message, status_code: determine_error_code(e.message) }
  rescue StandardError => e
    Rails.logger.error "Unexpected error in payment verification: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: 'Internal server error', status_code: 500 }
  end
  
  private
  
  attr_reader :reference, :current_reader, :purchase
  
  def validate_reference!
    raise VerificationError, 'Payment reference is required' unless reference.present?
    raise VerificationError, 'Invalid reference format' unless valid_reference_format?
  end
  
  def valid_reference_format?
    reference.is_a?(String) && 
    reference.length.between?(5, 100) &&
    reference.match?(/\A[a-zA-Z0-9_-]+\z/)
  end
  
  def find_purchase!
    @purchase = if current_reader
                  current_reader.purchases.find_by(transaction_reference: reference)
                else
                  Purchase.find_by(transaction_reference: reference)
                end
    
    raise VerificationError, 'Purchase record not found' unless @purchase
  end
  
  def already_verified?
    if purchase.purchase_status == 'completed'
      Rails.logger.info "Payment already verified for reference: #{reference}"
      true
    else
      false
    end
  end
  
  def validate_purchase_state!
    unless purchase.purchase_status == 'pending'
      raise VerificationError, 'Purchase is not in pending state'
    end
  end
  
  def verify_with_provider!
    paystack = PaystackService.new
    result = paystack.verify_transaction(reference)
    
    unless result[:success]
      mark_as_failed!("Paystack API error: #{result[:error]}")
      raise VerificationError, 'Payment verification failed'
    end
    
    unless result[:data]['status'] == 'success'
      mark_as_failed!("Payment status: #{result[:data]['status']}")
      raise VerificationError, 'Payment was not successful'
    end
    
    verify_amount!(result[:data])
    complete_payment!(result[:data])
  end
  
  def verify_amount!(payment_data)
    paystack_amount = payment_data['amount'].to_i
    expected_amount = (purchase.amount * 100).to_i
    
    if paystack_amount != expected_amount
      Rails.logger.error "SECURITY: Amount mismatch for #{purchase.id}. Expected: #{expected_amount}, Got: #{paystack_amount}"
      mark_as_failed!("Amount verification failed")
      raise VerificationError, 'Payment amount verification failed'
    end
  end
  
  def complete_payment!(payment_data)
    Purchase.transaction do
      # First mark the purchase as completed
      purchase.update!(
        purchase_status: 'completed',
        payment_verified_at: Time.current
      )
      
      # Calculate revenue distribution
      calculation = RevenueCalculationService.new(purchase).calculate
      
      # Create author revenue record
      AuthorRevenue.create!(
        author: purchase.book.author,
        purchase: purchase,
        amount: purchase.author_revenue,
        status: 'pending',
        notes: "Sale of #{purchase.book.title} (#{purchase.content_type})"
      )
    end
    
    Rails.logger.info "Payment completed and revenue calculated for purchase: #{purchase.id}"
  end
    
    Rails.logger.info "Payment completed for purchase: #{purchase.id}"
  end
  
  def mark_as_failed!(reason)
    Purchase.transaction do
      purchase.update!(purchase_status: 'failed')
    end
    Rails.logger.error "Payment failed for #{purchase.id}: #{reason}"
  end
  
  def build_success_response
    {
      purchase_id: purchase.id,
      book_title: purchase.book.title,
      amount: purchase.amount,
      content_type: purchase.content_type,
      reading_token: generate_reading_token,
      verified_at: purchase.payment_verified_at&.iso8601
    }
  end
  
  def generate_reading_token
    JWT.encode(
      { 
        sub: purchase.reader_id,
        purchase_id: purchase.id,
        content_type: purchase.content_type,
        book_id: purchase.book.id,
        exp: 4.hours.from_now.to_i
      },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end
  
  def determine_error_code(message)
    case message
    when /amount.*verification.*failed/i then 409
    when /not successful/i then 402
    when /not found/i then 404
    when /required/i, /invalid.*format/i then 422
    when /not in pending/i then 409
    else 502
    end
  end
end