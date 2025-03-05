class BookSerializer
    include JSONAPI::Serializer

    attributes  :id, :title, :description, :edition_number, :contributors,
                :primary_audience, :publishing_rights, :ebook_price, :audiobook_price,
                :unique_book_id, :unique_audio_id, :created_at, :updated_at,
                :ai_generated_image, :explicit_images, :subtitle, :bio,
                :categories, :keywords, :book_isbn, :terms_and_conditions

    attribute :cover_image_url do |book|
        book.cover_image.attached? ? book.standardized_cover_url : nil
    end
  
    attribute :cover_thumbnail_url do |book|
        book.cover_image.attached? ? book.cover_thumbnail_url : nil
    end

    attribute :ebook_file_url do |book|
        book.ebook_file.attached? ? book.ebook_file.url : nil
    end

    attribute :audiobook_file_url do |book|
        book.audiobook_file.attached? ? book.audiobook_file.url : nil
    end    
end