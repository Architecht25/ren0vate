# V2 — Lot 0 : cabinet d'architecture ou entreprise, optionnel (cahier des
# charges V2 §4). Posé en fondation minimale ; pas encore utilisé par un
# contrôleur ou une policy avant qu'un lot fonctionnel en ait besoin.
class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  KINDS = %w[architecture_firm contractor_company].freeze

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
end
