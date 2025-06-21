class Purchase < ApplicationRecord
  belongs_to :reader
  belongs_to :book
  has_one :author_revenue

  # Enums for content_type and purchase_status
  enum content_type: { ebook: 'ebook', audiobook: 'audiobook' }
  enum purchase_status: { pending: 'pending', completed: 'completed', failed: 'failed' }

  # Enhanced Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :content_type, presence: true
  validates :purchase_status, presence: true
  validates :purchase_date, presence: true
  validates :transaction_reference, presence: true, uniqueness: true
  validates :reader_id, uniqueness: { 
    scope: [:book_id, :content_type], 
    conditions: -> { where(purchase_status: 'completed') },
    message: "You already own this book"
  }

  # Scopes for common queries
  scope :completed, -> { where(purchase_status: 'completed') }
  scope :pending, -> { where(purchase_status: 'pending') }
  scope :by_content_type, ->(type) { where(content_type: type) }

  # Callbacks
  before_create :set_purchase_date

  private

  def set_purchase_date
    self.purchase_date ||= Time.current
  end

  # Helper methods
 def can_be_downloaded?
    completed? && payment_verified_at.present?
  end

  def formatted_amount
    "₦#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end
