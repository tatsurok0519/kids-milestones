class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :name, length: { maximum: 15 }, allow_nil: true
  validates :name, presence: true

  has_many :children, dependent: :destroy
end
