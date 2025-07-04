class User < ApplicationRecord
  has_many :simulations
  has_many :properties
  has_many :projects
  has_many :requests
  has_many :referrals
  has_many :notifications
  has_many :documents

  belongs_to :last_active_simulation, class_name: "Simulation", optional: true

  validates :email, presence: true, uniqueness: true
end
