class StorefrontBookSerializer
    include JSONAPI::Serializer
  
    attributes :title, :description, :ebook_price, :created_at, :total_pages, :categories
  
    attribute :cover_image_url do |book|
      Rails.application.routes.url_helpers.url_for(book.cover_image) if book.cover_image.attached?
    end
  
    attribute :author do |book|
      {
        id: book.author.id,
        name: "#{book.author.first_name} #{book.author.last_name}"
      }
    end
  
    attribute :average_rating do |book|
      book.reviews.average(:rating)&.round(2) || 0
    end
  
    attribute :reviews do |book|
      book.reviews.includes(:reader).map do |review|
        {
          id: review.id,
          rating: review.rating,
          comment: review.comment,
          created_at: review.created_at,
          reader: {
            id: review.reader.id,
            name: review.reader.first_name
          }
        }
      end
    end
  
    attribute :reviews_count do |book|
      book.reviews.count
    end
  
    attribute :likes_count do |book|
      book.likes.count
    end
  end