class Property < ApplicationRecord
  belongs_to :user
  has_many :simulations
  has_many :projects
  has_many :requests
  has_many :documents

  validates :address, :type_bien, presence: true
end
