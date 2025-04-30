class BookSerializer
  include JSONAPI::Serializer

  attributes :id, :title, :description, :edition_number, :contributors,
             :primary_audience, :publishing_rights, :ebook_price, :audiobook_price,
             :unique_book_id, :unique_audio_id, :created_at, :updated_at,
             :ai_generated_image, :explicit_images, :subtitle, :bio,
             :categories, :keywords, :book_isbn, :terms_and_conditions

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
end
