class Book < ApplicationRecord
  before_create :generate_unique_ids

  belongs_to :author
  has_many :purchases
  has_many :listeners, through: :purchases
  has_many :reviews
  has_many :chapters

  # Active Storage attachments
  has_one_attached :ebook_file
  has_one_attached :audiobook_file
  has_one_attached :cover_image

  # Validations
  validates :title, presence: true
  validates :unique_book_id, uniqueness: true, allow_nil: true
  validates :unique_audio_id, uniqueness: true, allow_nil: true
  validate  :tags_must_be_valid
  validate  :keywords_must_be_valid

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

  private

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

  def tags_must_be_valid
    if tags.present?
      if !tags.is_a?(Array)
        errors.add(:tags, "must be an array")
      elsif tags.any? { |tag| !tag.is_a?(String) || tag.blank? }
        errors.add(:tags, "can only contain non-empty strings")
      end
    end
  end

  def keywords_must_be_valid
    if keywords.present?
      if !keywords.is_a?(Array)
        errors.add(:keywords, "must be an array")
      elsif keywords.any? { |keyword| !keyword.is_a?(String) || keyword.blank? }
        errors.add(:keywords, "can only contain non-empty strings")
      end
    end
  end
end
