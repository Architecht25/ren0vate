class Request < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project
  belongs_to :simulation, optional: true

  has_many :request_progresses
  has_many :documents

  validates :status, presence: true
end
