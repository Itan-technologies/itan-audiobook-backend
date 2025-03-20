class BookSerializer
    include JSONAPI::Serializer

    attributes  :id, :title, :description, :edition_number, :contributors,
                :primary_audience, :publishing_rights, :ebook_price, :audiobook_price,
                :unique_book_id, :unique_audio_id, :created_at, :updated_at,
                :ai_generated_image, :explicit_images, :subtitle, :bio,
                :categories, :keywords, :book_isbn, :terms_and_conditions

    attribute :cover_image_url do |book|
        Rails.application.routes.url_helpers.url_for(book.cover_image) if book.cover_image.attached?
    end

    attribute :ebook_file_url do |book|
        Rails.application.routes.url_helpers.url_for(book.ebook_file) if book.ebook_file.attached?
    end
end