class Project < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :request, optional: true
  has_many :works
  has_many :documents

  validates :nom, presence: true
end
