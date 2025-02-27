class Review < ApplicationRecord
  belongs_to :listener
  belongs_to :book
end
