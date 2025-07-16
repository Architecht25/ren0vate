class Request < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  has_many :request_progresses
  has_many :documents

  validates :status, presence: true
  validates :title, presence: true
  validates :description, presence: true
  validates :region, presence: true

  # Scope pour récupérer les demandes récentes
  scope :recent, -> { order(created_at: :desc) }
end
