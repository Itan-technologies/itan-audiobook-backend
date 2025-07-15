class Like < ApplicationRecord
    belongs_to :book
    belongs_to :reader

    validates :reader_id, uniqueness: { scope: :book_id }
end
