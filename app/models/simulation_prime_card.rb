class SimulationPrimeCard < ApplicationRecord
  belongs_to :simulation
  belongs_to :prime

  validates :prime_id, uniqueness: { scope: :simulation_id }
end
