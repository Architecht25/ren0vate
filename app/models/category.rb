class Category < ApplicationRecord
  has_many :primes

  validates :code, :description, presence: true
  validates :code, uniqueness: true
end
