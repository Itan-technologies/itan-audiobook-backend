# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://develop.dh6o3qh0ijr1u.amplifyapp.com", "https://itan.app", "https://publish.itan.app"

    # Explicitly specify the ActiveStorage paths
    resource "/rails/active_storage/direct_uploads",
      headers: :any,
      methods: [:post],
      credentials: true,
      expose: ['ETag']
    
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head], 
      expose: ['access-token', 'expiry', 'token-type', 'Authorization'],      
      credentials: true
  end
end
