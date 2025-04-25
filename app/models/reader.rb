class Reader < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self
  
  before_create :set_jti

  has_many :books
  has_many :notifications
  has_many :reviews
  has_many :chapters
  has_many :purchases

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
 end
