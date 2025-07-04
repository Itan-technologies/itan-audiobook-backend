class Reader < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  before_create :set_jti

  # Associations - Access through purchases, not ownership
  has_many :purchases, dependent: :destroy
  has_many :purchased_books, through: :purchases, source: :book
  has_many :accessible_chapters, through: :purchased_books, source: :chapters
  
  # Direct associations
  has_many :notifications, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :likes, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true

  # Helper methods for access checking
  def owns_book?(book)
    purchased_books.include?(book)
  end

  def can_access_chapter?(chapter)
    owns_book?(chapter.book)
  end
  
  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
