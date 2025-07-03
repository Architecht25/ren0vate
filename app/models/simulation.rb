class Simulation < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :category
end
