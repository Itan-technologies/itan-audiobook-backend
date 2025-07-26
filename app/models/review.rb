class Review < ApplicationRecord
  belongs_to :reader
  belongs_to :book

  validate :rating_or_comment_present

  def rating_or_comment_present
    return unless rating.blank? && comment.blank?

    errors.add(:base, 'Either rating or comment must be present')
  end
end
