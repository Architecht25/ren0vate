class Lot < ApplicationRecord
  belongs_to :project
  has_many :project_member_lots, dependent: :destroy
  has_many :project_members, through: :project_member_lots

  validates :key, presence: true, uniqueness: { scope: :project_id }
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  # Modèles pré-remplis proposés à la création d'un chantier (cahier des
  # charges V2 §4 : "lot (toiture, menuiseries, isolation, techniques,
  # finitions… modèles pré-remplis, personnalisables)"). Le propriétaire peut
  # renommer/ajouter/retirer des lots après création — ceci ne contraint rien
  # en base, juste les suggestions proposées par le formulaire.
  DEFAULT_TEMPLATE = [
    { key: "toiture", name: "Toiture" },
    { key: "menuiseries", name: "Menuiseries" },
    { key: "isolation", name: "Isolation" },
    { key: "techniques", name: "Techniques (chauffage, ventilation, électricité)" },
    { key: "finitions", name: "Finitions" }
  ].freeze

  def self.build_default_set_for(project)
    DEFAULT_TEMPLATE.map.with_index do |attrs, index|
      project.lots.build(attrs.merge(position: index))
    end
  end
end
