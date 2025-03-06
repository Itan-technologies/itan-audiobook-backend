# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Admin.create!(
#   email: 'admin@example.com',
#   password: 'password123@1',
#   password_confirmation: 'password123@1'
# )

# puts 'Admin seeded'

book = Book.order(created_at: :desc).first
puts "Book: #{book.title}"
puts "Original dimensions: #{book.cover_image.metadata['width']}x#{book.cover_image.metadata['height']}"
puts "Original URL: #{book.cover_image.url}"
puts "Standard URL: #{book.standardized_cover_url}"
puts "Thumbnail URL: #{book.cover_thumbnail_url}"