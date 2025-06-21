class PurchaseService
  class ValidationError < StandardError; end
  
  def initialize(reader, book, content_type)
    @reader = reader
    @book = book
    @content_type = content_type
  end

  def create_purchase
    validate_purchase!
    
    result = nil

    reference = generate_reference
    
    Purchase.transaction do
      @purchase = create_purchase_record(reference)
      payment_result = initialize_payment(reference)
      
      # If payment initialization fails, rollback everything
      unless payment_result[:success]
        raise StandardError, payment_result[:error]
      end
      
      result = {
        success: true,
        data: {
          purchase_id: @purchase.id,
          authorization_url: payment_result[:data]['authorization_url'],
          reference: reference,
          amount: @purchase.amount,
          book_title: @book.title,
          content_type: @purchase.content_type
        }
      }
    end
    
    result
    
  rescue ValidationError => e
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Purchase creation failed: #{e.message}"
    { success: false, error: 'Payment initialization failed' }
  end

  private

  def validate_purchase!
    raise ValidationError, 'You already own this book' if duplicate_purchase?
    raise ValidationError, 'Content not available' unless content_available?
    raise ValidationError, 'Invalid content type' unless valid_content_type?
  end

  def duplicate_purchase?
    @reader.purchases.exists?(
      book: @book,
      purchase_status: 'completed'
    )
  end

  def content_available?
    case @content_type
    when 'ebook'
      @book.ebook_price.present?
    when 'audiobook'
      @book.audiobook_price.present?
    else
      false
    end
  end

  def valid_content_type?
    %w[ebook audiobook].include?(@content_type)
  end

  def create_purchase_record(reference)
    @reader.purchases.create!(
      book: @book,
      amount: calculate_amount,
      content_type: @content_type,
      purchase_status: 'pending',
      purchase_date: Time.current,
      transaction_reference: reference,
      paystack_fee: nil, 
      delivery_fee: nil,
      admin_revenue: nil,
      author_revenue_amount: nil,
      file_size_mb: nil,
      fee_data_source: nil
    )
  end

  def initialize_payment(reference)
    paystack = PaystackService.new
    paystack.initialize_transaction(
      email: @reader.email,
      amount: calculate_amount,
      reference: reference,
      metadata: {
        book_id: @book.id,
        reader_id: @reader.id,
        content_type: @content_type,
        book_title: @book.title
      },
      callback_url: "#{ENV.fetch('FRONTEND_URL')}/payment/callback"
    )
  end

  def calculate_amount
    @content_type == 'ebook' ? @book.ebook_price : @book.audiobook_price
  end

  def generate_reference
    "TRX_#{SecureRandom.hex(8)}_#{Time.current.to_i}"
  end
end