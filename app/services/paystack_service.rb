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
  # Convert naira to kobo for Paystack
  amount_in_kobo = (amount * 100).to_i

  # Generate reference if not provided
  reference ||= generate_reference

  body = {
    email: email,
    amount: amount_in_kobo, 
    reference: reference,     # Now correctly defined
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
  
  result  # Explicitly return the result
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
