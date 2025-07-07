class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :simulations, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :referrals, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :documents, dependent: :destroy

  belongs_to :last_active_simulation, class_name: "Simulation", optional: true
end
