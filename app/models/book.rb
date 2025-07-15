class Book < ApplicationRecord
  before_create :generate_unique_ids
  before_validation :ensure_arrays_format
  # before_save :check_price_size_ratio

  belongs_to :author
  has_many :purchases
  has_many :readers, through: :purchases
  has_many :reviews
  has_many :chapters
  has_many :likes
  has_many :liked_by_readers, through: :likes, source: :reader

  # Active Storage attachments
  has_one_attached :ebook_file
  has_one_attached :audiobook_file
  has_one_attached :cover_image

  # Validations
  validates :title, presence: true
  # validates :unique_book_id, uniqueness: true, allow_nil: true
  # validates :unique_audio_id, uniqueness: true, allow_nil: true
  # validate  :tags_must_be_valid
  # validate  :keywords_must_be_valid
  # validate :contributors_must_be_valid
  # validate :categories_must_be_valid

  enum approval_status: {
    pending: 'pending',
    approved: 'approved',
    rejected: 'rejected'
  }, _default: 'pending'

  # Scopes to filter books by status
  scope :pending, -> { where(approval_status: 'pending') }
  scope :approved, -> { where(approval_status: 'approved') }
  scope :rejected, -> { where(approval_status: 'rejected') }
  # Only show approved books to the public
  scope :publicly_visible, -> { approved }

  # Enable nested attributes
  # accepts_nested_attributes_for :book_contributors,
  #                               allow_destroy: true,
  #                               reject_if: :all_blank

  # accepts_nested_attributes_for :book_categories,
  # allow_destroy: true,
  # reject_if: :all_blank

  # Add a method to get standardized cover
  # def standardized_cover_url
  #   return nil unless cover_image.attached?

  #   # Check if already the right dimensions
  #   if cover_image.metadata["width"] == 2560 && cover_image.metadata["height"] == 1600
  #     # Already correct dimensions, just return normal URL
  #     cover_image.url
  #   else
  #     # Return a variant URL instead of replacing the image
  #     cover_image.variant(
  #       resize_to_fill: [2560, 1600],
  #       format: :jpg,
  #       strip: true,
  #       saver: { quality: 90 }
  #     ).processed.url
  #   end
  # end

  # Add smaller versions for different contexts
  # def cover_thumbnail_url
  #   return nil unless cover_image.attached?

  #   cover_image.variant(
  #     resize_to_fill: [300, 188],
  #     format: :jpg,
  #     strip: true,
  #     saver: { quality: 80 }
  #   ).processed.url
  # end

  # In Book model

  # def check_price_size_ratio
  #   return unless ebook.attached? || audiobook.attached?

  #   content_types = []
  #   content_types << 'ebook' if ebook.attached?
  #   content_types << 'audiobook' if audiobook.attached?

  #   content_types.each do |type|
  #     attachment = type == 'ebook' ? ebook : audiobook
  #     size_mb = (attachment.blob.byte_size.to_f / (1024 * 1024)).round(2)
  #     price_field = type == 'ebook' ? :ebook_price : :audiobook_price
  #     current_price = send(price_field)

  #     # Calculate minimum recommended price
  #     min_price = RevenueCalculationService.calculate_minimum_recommended_price(size_mb)

  #     if current_price < min_price
  #       # Set warning flag and store in JSON field (add this column to your model)
  #       self.price_warnings ||= {}
  #       self.price_warnings[type] = {
  #         current_price: current_price/100.0,
  #         recommended_price: min_price/100.0,
  #         file_size_mb: size_mb,
  #         estimated_earnings: RevenueCalculationService.estimate_author_earnings(current_price/100.0, size_mb)
  #       }
  #     end
  #   end
  # end

  private

  def ensure_arrays_format
    self.keywords = keywords.split(',').map(&:strip) if keywords.present? && !keywords.is_a?(Array)

    return unless tags.present? && !tags.is_a?(Array)

    self.tags = tags.split(',').map(&:strip)
  end

  def generate_unique_ids
    # Use a transaction to prevent race conditions
    Book.transaction do
      # Use a faster query that only locks what we need
      last_number = Book.where.not(unique_book_id: nil)
        .order(created_at: :desc)
        .lock('FOR UPDATE')
        .limit(1)
        .pluck(:unique_book_id)
        .first&.gsub(/[^\d]/, '')&.to_i || 1000

      # Set both IDs using the same number but different prefixes
      next_number = last_number + 1
      self.unique_book_id = "BOO#{next_number}"
      self.unique_audio_id = "AOO#{next_number}"
    end
  end

  # def tags_must_be_valid
  #   if tags.present?
  #     if !tags.is_a?(Array)
  #       errors.add(:tags, "must be an array")
  #     elsif tags.any? { |tag| !tag.is_a?(String) || tag.blank? }
  #       errors.add(:tags, "can only contain non-empty strings")
  #     end
  #   end
  # end

  # def keywords_must_be_valid
  #   if keywords.present?
  #     if !keywords.is_a?(Array)
  #       errors.add(:keywords, "must be an array")
  #     elsif keywords.any? { |keyword| !keyword.is_a?(String) || keyword.blank? }
  #       errors.add(:keywords, "can only contain non-empty strings")
  #     end
  #   end
  # end

  # def contributors_must_be_valid
  #   if contributors.present?
  #     unless contributors.is_a?(Array)
  #       errors.add(:contributors, "must be an array")
  #       return
  #     end

  #     if contributors.empty?
  #       errors.add(:contributors, "must have at least one contributor")
  #       return
  #     end
  #   end
  # end

  # def categories_must_be_valid
  #   if categories.present?
  #     unless categories.is_a?(Array)
  #       errors.add(:categories, "must be an array")
  #       return
  #     end
  #   end
  # end
end
