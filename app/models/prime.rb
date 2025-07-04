class Prime < ApplicationRecord
  belongs_to :category
  has_many :simulation_prime_cards
  has_many :simulations, through: :simulation_prime_cards
  has_many :works
  has_many :request_progresses

  validates :slug, :titre, presence: true
  validates :slug, uniqueness: true
end
