class Purchase < ApplicationRecord
  belongs_to :reader
  belongs_to :book

  # Enums for content_type and purchase_status
  enum content_type: { ebook: 'ebook', audiobook: 'audiobook' }
  enum purchase_status: { pending: 'pending', completed: 'completed', failed: 'failed' }

  # Validations
  validates :amount, presence: true
  validates :content_type, presence: true
  validates :purchase_status, presence: true
  validates :purchase_date, presence: true
end
