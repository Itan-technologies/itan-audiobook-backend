class ReadingStatus < ApplicationRecord
    belongs_to :reader
    belongs_to :book
  
    enum status: { not_started: 'not_started', in_progress: 'in_progress', finished: 'finished' }
  
    validates :reader_id, :book_id, :status, presence: true
    validates :status, inclusion: { in: statuses.keys }
    validates :reader_id, uniqueness: { scope: :book_id }
  end