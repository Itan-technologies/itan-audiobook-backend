class AuthorSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :created_at, :first_name, :last_name,
             :bio, :phone_number, :country, :location, :created_at,
             :updated_at, :two_factor_enabled, :preferred_2fa_method

  attribute :author_profile_image_url do |author|
    if author.author_profile_image.attached?
      begin
        Rails.application.routes.url_helpers.url_for(author.author_profile_image)
      rescue StandardError => e
        Rails.logger.error("Failed to generate profile image URL: #{e.message}")
        nil
      end
    else
      nil # or a default image URL
    end
  end
end
