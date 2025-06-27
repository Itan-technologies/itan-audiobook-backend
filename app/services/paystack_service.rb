class PaystackService
  include HTTParty
  base_uri 'https://api.paystack.co'

  def initialize
    @headers = {
      'Authorization' => "Bearer #{ENV.fetch('PAYSTACK_SECRET_KEY', nil)}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def initialize_transaction(email:, amount:, reference: nil, metadata: {}, callback_url: nil)
    # Generate reference if not provided
    reference ||= generate_reference

    body = {
      email: email,
      amount: amount, 
      reference: reference,
      currency: "USD",
      metadata: metadata
    }

    body[:callback_url] = callback_url if callback_url

    response = self.class.post(
      '/transaction/initialize',
      headers: @headers,
      body: body.to_json
    )

    result = handle_response(response)
    
    # Include reference in the result
    if result[:success]
      result[:reference] = reference
    end
    
    result
  end

  def initiate_transfer(recipient_code, amount_in_kobo, reference = nil, reason = nil)
    reference ||= "TFR_#{SecureRandom.hex(8)}"
    
    body = {
      source: "balance",
      amount: amount_in_kobo,
      recipient: recipient_code,
      currency: "NGN",
      reference: reference
    }
    
    body[:reason] = reason if reason
    
    response = self.class.post(
      '/transfer',
      headers: @headers,
      body: body.to_json
    )
    
    handle_response(response)
  end

  def verify_transfer(reference)
    response = self.class.get(
      "/transfer/verify/#{reference}",
      headers: @headers
    )
    
    handle_response(response)
  end

  def verify_transaction(reference)
    response = self.class.get("/transaction/verify/#{reference}", {
      headers: @headers
    })

    if response.success?
      {
        success: true,
        data: response.parsed_response['data']
      }
    else
      {
        success: false,
        error: response.parsed_response['message'] || 'Payment verification failed'
      }
    end
    rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def self.resolve_account(account_number, bank_code)
    require 'uri'
    require 'net/http'
    
    url = URI("https://api.paystack.co/bank/resolve?account_number=#{account_number}&bank_code=#{bank_code}")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
    
    response = http.request(request)
    JSON.parse(response.body)
    rescue => e
    Rails.logger.error "PaystackService Error: #{e.message}"
    { "status" => false, "message" => "Service unavailable" }
  end

  def self.list_banks
    require 'uri'
    require 'net/http'
    
    url = URI("https://api.paystack.co/bank")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    request["Authorization"] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
    
    response = http.request(request)
    JSON.parse(response.body)
    rescue => e
      Rails.logger.error "PaystackService Error (list_banks): #{e.message}"
      { "status" => false, "message" => "Service unavailable" }
  end

  def create_transfer_recipient(name:, account_number:, bank_code:)
    body = {
      type: "nuban",
      name: name,
      account_number: account_number,
      bank_code: bank_code,
      currency: "NGN"
    }
    response = self.class.post(
      '/transferrecipient',
      headers: @headers,
      body: body.to_json
    )
    handle_response(response)
  end

  private

  def handle_response(response)
    result = JSON.parse(response.body)

    if response.success? && result['status']
      {
        success: true,
        data: result['data']
      }
    else
      {
        success: false,
        error: result['message']
      }

    end
  end

  def generate_reference
    "TRX_#{SecureRandom.hex(8)}_#{Time.current.to_i}"
  end
end
