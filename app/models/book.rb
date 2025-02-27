class Book < ApplicationRecord
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
end