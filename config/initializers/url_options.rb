Rails.application.config.to_prepare do
  ActiveStorage::Current.url_options = {
    host: ENV.fetch('HOST') { 'localhost:3000' },
    protocol: ENV.fetch('PROTOCOL') { 'http' }
  }
end
