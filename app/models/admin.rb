class Admin < ApplicationRecord
  self.primary_key = :id
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable

  #associations                    
 has_many :notifications, as: :user
end
