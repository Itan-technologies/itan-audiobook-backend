class RevenueCalculationService
  # Constants
  PAYSTACK_PERCENTAGE = 0.039 # 3.9% - for fallback calculation only
  PAYSTACK_FIXED_FEE_NAIRA = 100.0 # 100 NGN fixed fee - for fallback calculation only
  NGN_TO_USD_RATE = 1500.0 # Update as needed - for fallback calculation only
  PAYSTACK_FIXED_FEE_USD = (PAYSTACK_FIXED_FEE_NAIRA / NGN_TO_USD_RATE).round(4)

  DELIVERY_RATE_PER_MB = 0.15
  ADMIN_PERCENTAGE = 0.30
  AUTHOR_PERCENTAGE = 0.70

  def initialize(purchase)
    @purchase = purchase
    @book = purchase.book
    @content_type = purchase.content_type
  end

  def calculate
    Rails.logger.info "🔶 Starting revenue calculation for purchase #{@purchase.id}"
    Rails.logger.info "🔶 Book: #{@book.title}, Author ID: #{@book.author_id || 'MISSING!!!'}"

    # Get the gross amount (what customer paid)
    gross_amount = @purchase.amount.to_f / 100.0

    # Calculate file size
    file_size_mb = get_file_size_in_mb

    # Get the ACTUAL settled amount from Paystack
    settlement_data = get_paystack_settlement_amount(@purchase.transaction_reference)

    # The amount AFTER Paystack has deducted their fees
    amount_after_paystack = settlement_data[:settled_amount]

    # The fee Paystack deducted
    paystack_fee = settlement_data[:actual_fee]

    # Track fee data source for logging
    fee_source = settlement_data[:source] || 'unknown'
    Rails.logger.info "🔶 Using #{fee_source} fee data for purchase #{@purchase.id}: $#{paystack_fee}"

    # Calculate delivery fee
    delivery_fee = calculate_delivery_fee(file_size_mb, gross_amount)

    # Amount for splitting between admin and author
    amount_for_split = [amount_after_paystack - delivery_fee, 0].max

    # Split the remaining amount
    author_revenue = (amount_for_split * AUTHOR_PERCENTAGE).round(2)
    admin_revenue = (amount_for_split * ADMIN_PERCENTAGE).round(2)

    Rails.logger.info "🔶 Calculated splits - Author: $#{author_revenue}, Admin: $#{admin_revenue}"

    # Update purchase with calculated values
    @purchase.update(
      paystack_fee: paystack_fee,
      delivery_fee: delivery_fee,
      file_size_mb: file_size_mb,
      admin_revenue: admin_revenue,
      author_revenue_amount: author_revenue,
      fee_data_source: fee_source # Add this column to purchases table
    )

    # CRITICAL MISSING STEP: Create the AuthorRevenue record
    if @book.author_id.present?
      Rails.logger.info "🔶 Creating AuthorRevenue record for author_id: #{@book.author_id}"

      begin
        author_revenue_record = AuthorRevenue.create!(
          author_id: @book.author_id,
          purchase_id: @purchase.id,
          amount: author_revenue,
          status: 'pending'
        )
        Rails.logger.info "✅ AuthorRevenue record created! ID: #{author_revenue_record.id}"
      rescue StandardError => e
        Rails.logger.error "❌ FAILED TO CREATE AUTHOR REVENUE RECORD: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    else
      Rails.logger.error "❌ Cannot create AuthorRevenue - Book #{@book.id} has no author_id!"
    end

    # Return detailed breakdown
    {
      gross_amount: gross_amount,
      paystack_fee: paystack_fee,
      fee_data_source: fee_source,
      amount_after_paystack: amount_after_paystack.round(2),
      file_size_mb: file_size_mb,
      delivery_fee: delivery_fee,
      amount_for_split: amount_for_split.round(2),
      admin_revenue: admin_revenue,
      author_revenue: author_revenue
    }
  end

  # Get actual settlement amount from Paystack
  def get_paystack_settlement_amount(reference)
    # Use the instance of your PaystackService class
    paystack_service = PaystackService.new

    # Call Paystack API to get the actual settled amount
    begin
      response = paystack_service.verify_transaction(reference)

      if response[:success] && response[:data]
        # Convert amount from kobo/cents to naira/dollars
        amount = response[:data]['amount'].to_f / 100.0

        # Get fees from Paystack response
        if response[:data]['fees']
          actual_fee = response[:data]['fees'].to_f / 100.0
          settled_amount = amount - actual_fee

          return {
            settled_amount: settled_amount.round(2),
            actual_fee: actual_fee.round(2),
            source: 'paystack_api'
          }
        else
          # No fee information provided, use fallback calculation
          # but mark it clearly as estimated
          Rails.logger.warn "Paystack didn't provide fee information for transaction: #{reference}"
          paystack_fee = (amount * PAYSTACK_PERCENTAGE) + PAYSTACK_FIXED_FEE_USD

          return {
            settled_amount: (amount - paystack_fee).round(2),
            actual_fee: paystack_fee.round(2),
            source: 'estimated_missing_fee'
          }
        end
      else
        error_msg = response[:error] || 'Unknown verification error'
        Rails.logger.error "Paystack verification failed: #{error_msg}"
      end
    rescue StandardError => e
      Rails.logger.error "Failed to get Paystack settlement: #{e.message}"
    end

    # Fallback to calculation if API call completely fails
    gross_amount = @purchase.amount.to_f / 100.0
    paystack_fee = (gross_amount * PAYSTACK_PERCENTAGE) + PAYSTACK_FIXED_FEE_USD

    {
      settled_amount: (gross_amount - paystack_fee).round(2),
      actual_fee: paystack_fee.round(2),
      source: 'estimated_api_failure'
    }
  end

  private

  def get_file_size_in_mb
    if @content_type == 'ebook' && @book.ebook_file.attached?
      (@book.ebook_file.blob.byte_size.to_f / (1024 * 1024)).round(2)
    elsif @content_type == 'audiobook' && @book.audiobook_file.attached?
      (@book.audiobook_file.blob.byte_size.to_f / (1024 * 1024)).round(2)
    else
      @content_type == 'audiobook' ? 10.0 : 1.0
    end
  rescue StandardError => e
    Rails.logger.error "Error calculating file size: #{e.message}"
    @content_type == 'audiobook' ? 10.0 : 1.0
  end

  def calculate_delivery_fee(file_size_mb, _price)
    (file_size_mb * DELIVERY_RATE_PER_MB).round(2)
  end
end
