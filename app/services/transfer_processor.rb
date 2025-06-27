class TransferProcessor
  require 'net/http'
  require 'json'

  def self.fetch_ngn_rate
    app_id = ENV['OPENEXCHANGE_APP_ID']
    url = URI("https://openexchangerates.org/api/latest.json?app_id=#{app_id}")
    begin
      response = Net::HTTP.get(url)
      data = JSON.parse(response) rescue nil

      if data.nil? || !data["rates"] || !data["rates"]["NGN"]
        Rails.logger.error "Exchange rate fetch failed or NGN rate missing. Response: #{response}"
        return nil
      end

      data["rates"]["NGN"]
    rescue => e
      Rails.logger.error "Error fetching exchange rate: #{e.message}"
      nil
    end
  end

  def self.process_batch(batch_id)
    Rails.logger.info "Starting process_batch for batch_id: #{batch_id}"

    usd_to_ngn = fetch_ngn_rate
    if usd_to_ngn.nil?
      Rails.logger.error "Failed to fetch USD to NGN rate. Aborting transfer."
      return { success: [], failed: [{ reason: "Could not fetch exchange rate" }] }
    end
    Rails.logger.info "Current USD to NGN rate: #{usd_to_ngn}"

    # Get all approved payments in this batch
    batch_payments = AuthorRevenue.where(
      payment_batch_id: batch_id,
      status: 'approved'
    ).group_by(&:author_id)

    Rails.logger.info "Found #{batch_payments.keys.size} authors in batch"

    results = { success: [], failed: [] }

    batch_payments.each do |author_id, payments|
      author = Author.find(author_id)
      banking_details = author.author_banking_detail

      Rails.logger.info "Processing author: #{author.email}, author_id: #{author_id}"
      Rails.logger.info "Banking details: #{banking_details.inspect}"

      # Skip if no verified banking details
      unless banking_details&.verified?
        Rails.logger.warn "No verified banking details for author: #{author.email}"
        payments.each do |payment|
          payment.update(
            status: 'transfer_failed',
            notes: "#{payment.notes}\nTransfer failed: No verified banking details"
          )
        end
        results[:failed] << { author: author.email, reason: "No verified banking details" }
        next
      end

      # Convert total USD to NGN
      total_usd = payments.sum(&:amount)
      total_ngn = (total_usd * usd_to_ngn).round(2)
      amount_in_kobo = (total_ngn * 100).to_i

      Rails.logger.info "Total USD: #{total_usd}, Total NGN: #{total_ngn}, Amount in kobo: #{amount_in_kobo}"

      # Initiate transfer via Paystack
      paystack = PaystackService.new
      transfer_reference = "TRF-#{SecureRandom.hex(8)}"
      Rails.logger.info "Initiating transfer: recipient_code=#{banking_details.recipient_code}, reference=#{transfer_reference}"

      transfer_result = paystack.initiate_transfer(
        banking_details.recipient_code,
        amount_in_kobo,
        transfer_reference,
        "Payment for batch #{batch_id}"
      )

      Rails.logger.info "Paystack transfer result: #{transfer_result.inspect}"

      if transfer_result[:success]
        # Mark payments as transferred
        payments.each do |payment|
          payment.update(
            status: 'transferred',
            transfer_reference: transfer_reference,
            transferred_at: Time.current
          )
        end
        results[:success] << { author: author.email, amount: total_ngn }
      else
        # Log failure
        error_message = transfer_result[:error] || "Unknown error"
        Rails.logger.error "Transfer failed for author: #{author.email}, reason: #{error_message}"
        payments.each do |payment|
          payment.update(
            status: 'transfer_failed',
            notes: "#{payment.notes}\nTransfer failed: #{error_message}"
          )
        end
        results[:failed] << { author: author.email, reason: error_message }
      end
    end

    Rails.logger.info "process_batch results: #{results.inspect}"
    results
  end
end