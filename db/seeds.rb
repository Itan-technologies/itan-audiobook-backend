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

# book = Book.order(created_at: :desc).first
# puts "Book: #{book.title}"
# puts "Original dimensions: #{book.cover_image.metadata['width']}x#{book.cover_image.metadata['height']}"
# puts "Original URL: #{book.cover_image.url}"
# puts "Standard URL: #{book.standardized_cover_url}"
# puts "Thumbnail URL: #{book.cover_thumbnail_url}"

# db/seeds.rb - More realistic page counts based on price
puts "📚 Updating book page counts based on pricing..."

Book.find_each do |book|
  if book.ebook_price.present?
    # More realistic page counts based on book price
    pages = case book.ebook_price
            when 0..1000     then rand(50..150)   # Short stories
            when 1001..3000  then rand(150..300)  # Medium novels
            when 3001..5000  then rand(300..500)  # Long novels
            when 5001..10000 then rand(400..600)  # Epic novels
            else rand(200..400)                   # Default
            end
    
    book.update!(total_pages: pages)
    puts "📖 #{book.title}: #{pages} pages (₦#{book.ebook_price})"
  end
end

puts "✅ All books updated with page counts!"