class TransferProcessor
    def self.process_batch(batch_id)
      # Get all approved payments in this batch
      batch_payments = AuthorRevenue.where(
        payment_batch_id: batch_id,
        status: 'approved'
      ).group_by(&:author_id)
      
      results = { success: [], failed: [] }
      
      batch_payments.each do |author_id, payments|
        author = Author.find(author_id)
        banking_details = author.author_banking_detail
        
        # Skip if no verified banking details
        unless banking_details&.verified?
          payments.each do |payment|
            payment.update(
              status: 'transfer_failed',
              notes: "#{payment.notes}\nTransfer failed: No verified banking details"
            )
          end
          results[:failed] << { author: author.email, reason: "No verified banking details" }
          next
        end
        
        # Calculate total amount for this author in this batch
        total_amount = payments.sum(&:amount)
        
        # Initiate transfer via Paystack
        paystack = PaystackService.new
        transfer_reference = "TRF-#{SecureRandom.hex(8)}"
        
        transfer_result = paystack.initiate_transfer(
          banking_details.recipient_code,
          total_amount,
          transfer_reference,
          "Payment for batch #{batch_id}"
        )
        
        if transfer_result[:success]
          # Mark payments as transferred
          payments.each do |payment|
            payment.update(
              status: 'transferred',
              transfer_reference: transfer_reference,
              transferred_at: Time.current
            )
          end
          results[:success] << { author: author.email, amount: total_amount }
        else
          # Log failure
          error_message = transfer_result[:error] || "Unknown error"
          payments.each do |payment|
            payment.update(
              status: 'transfer_failed',
              notes: "#{payment.notes}\nTransfer failed: #{error_message}"
            )
          end
          results[:failed] << { author: author.email, reason: error_message }
        end
      end
      
      results
    end
  end