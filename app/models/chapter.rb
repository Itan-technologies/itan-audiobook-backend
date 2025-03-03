class Chapter < ApplicationRecord
  belongs_to :book
  has_many :listeners

  belongs_to :book

  # Validations
  validates :title, presence: true
  validates :content, presence: true
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
