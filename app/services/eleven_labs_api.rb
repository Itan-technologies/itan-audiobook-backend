class ElevenLabsApi
  include HTTParty
  base_uri 'https://api.elevenlabs.io/v1'
  
  # Default voice and model settings
  DEFAULT_VOICE_ID = "21m00Tcm4TlvDq8ikWAM"
  DEFAULT_MODEL = "eleven_multilingual_v2"
  
  def initialize
    @api_key = ENV['ELEVEN_LABS_API_KEY']
    @headers = {
      "xi-api-key" => @api_key,
      "Content-Type" => "application/json"
    }
  end

  # Convert text to speech with flexible options
  def text_to_speech(text, voice_id = DEFAULT_VOICE_ID, options = {})
    validate_text!(text)

    # Set accept header for audio response
    headers = @headers.merge("Accept" => "audio/mpeg")
    
    response = self.class.post(
      "/text-to-speech/#{voice_id}",
      headers: headers,
      body: {
        text: text,
        model_id: options[:model_id] || DEFAULT_MODEL,
        voice_settings: {
          stability: options[:stability] || 0.5,
          similarity_boost: options[:similarity_boost] || 0.75,
          style: options[:style] || 0.0
        }.compact
      }.to_json
    )
    
    handle_response(response)
  end
  
  # Get available voices
  def get_voices
    headers = @headers.merge("Accept" => "application/json")
    response = self.class.get("/voices", headers: headers)
    handle_json_response(response)
  end
  
  # Get user subscription info
  def get_user_info
    headers = @headers.merge("Accept" => "application/json")
    response = self.class.get("/user", headers: headers)
    handle_json_response(response)
  end
  
  private
  
  def validate_text!(text)
    if text.blank?
      raise ArgumentError, "Text cannot be blank"
    end
  end
  
  # Handle responses expecting binary data (audio)
  def handle_response(response)
    if response.success?
      response.body  # Return raw binary data for audio
    else
      handle_error(response)
    end
  end
  
  # Handle responses expecting JSON data
  def handle_json_response(response)
    if response.success?
      # Explicitly parse JSON
      JSON.parse(response.body)
    else
      handle_error(response)
    end
  end
  
  def handle_error(response)
    case response.code
    when 401
      raise "ElevenLabs API authentication failed. Check your API key."
    when 429
      raise "ElevenLabs API rate limit exceeded. Please try again later."
    else
      error_msg = parse_error_message(response)
      Rails.logger.error "ElevenLabs API Error: #{response.code} - #{error_msg}"
      raise "ElevenLabs API Error (#{response.code}): #{error_msg}"
    end
  end
  
  def parse_error_message(response)
    begin
      # Explicitly parse error response
      error_data = JSON.parse(response.body.to_s)
      error_data["detail"] || error_data["message"] || "Unknown error"
    rescue JSON::ParserError
      response.body.to_s.truncate(100)
    end
  end
end