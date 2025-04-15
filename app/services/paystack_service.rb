class PaystackService
    include HTTParty
    base_uri 'https://api.paystack.co'

    def initialize
        @headers = {
           'Authorization' => "Bearer #{ENV['PAYSTACK_SECRET_KEY']}",
           'Content-Type' => 'application/json',
           'Accept' => 'application/json'
        }
    end

    def initialize_transaction(email:, amount:, metadata: {}, callback_url: nil)
        body = {
            email: email,
            amount: amount,
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

    private

    def handle_response(response)
        result = JSON.parse(response.body)

        if response.success? && result["status"]
            {
                success: true,
                data: result["data"]
            }
        else 
        {
            success: false,
           error: result["message"]
        }
        
        end
    end
end