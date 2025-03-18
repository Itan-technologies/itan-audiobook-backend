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
        if book.ebook_file.attached?
            begin
            url_options = { host: "localhost:3000", protocol: "http" }
            Rails.application.routes.url_helpers.rails_blob_url(book.ebook_file, url_options)
            rescue
            nil
            end
        end
    end

    attribute :audiobook_file_url do |book|
            if book.audiobook_file.attached?
                begin
                    url_options = { host: "localhost:3000", protocol: "http" }
                    Rails.application.routes.url_helpers.rails_blob_url(book.audiobook_file, url_options)
                rescue
                    nil
                end
            end
        end
end