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

  def initialize_transaction(email:, amount:, metadata: {}, callback_url: nil)
    body = {
      email: email,
      amount: (amount * 100).to_i,      
      metadata: metadata
    }

    body[:callback_url] = callback_url if callback_url

    response = self.class.post(
      '/transaction/initialize',
      headers: @headers,
      body: body.to_json
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
end
