class BookSerializer
  include JSONAPI::Serializer

  attributes :id, :title, :description, :edition_number, :contributors,
             :primary_audience, :publishing_rights, :ebook_price, :audiobook_price,
             :unique_book_id, :unique_audio_id, :created_at, :updated_at,
             :ai_generated_image, :explicit_images, :subtitle, :bio,
             :categories, :keywords, :book_isbn, :terms_and_conditions,
             :approval_status, :admin_feedback, :tags, :publisher, :first_name, :last_name,
             :total_pages

  attribute :cover_image_url do |book|
    if book.cover_image.attached?
      begin
        Rails.application.routes.url_helpers.url_for(book.cover_image)
      rescue StandardError => e
        Rails.logger.error("Failed to generate cover image URL for book #{book.id}: #{e.message}")
        nil
      end
    end
  end

  attribute :ebook_file_url do |book|
    if book.ebook_file.attached?
      begin
        Rails.application.routes.url_helpers.url_for(book.ebook_file)
      rescue StandardError => e
        Rails.logger.error("Failed to generate ebook file URL for book #{book.id}: #{e.message}")
        nil
      end
    end
  end

  attribute :audiobook_file_url do |book|
    if book.audiobook_file.attached?
      begin
        Rails.application.routes.url_helpers.url_for(book.audiobook_file)
      rescue StandardError => e
        Rails.logger.error("Failed to generate audiobook file URL for book #{book.id}: #{e.message}")
        nil
      end
    end
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
    book.reviews.map do |review|
      {
        id: review.id,
        reader_id: review.reader_id,
        rating: review.rating,
        comment: review.comment,
        created_at: review.created_at
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
