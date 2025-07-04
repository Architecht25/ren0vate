class Simulation < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  has_many :simulation_prime_cards, dependent: :destroy
  has_many :primes, through: :simulation_prime_cards
  has_many :documents

  has_one :request

  validates :region, :titre, :source, presence: true
end
