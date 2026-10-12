class Phase < ApplicationRecord
  belongs_to :project
  has_many :project_documents, dependent: :nullify

  validates :key, presence: true, uniqueness: { scope: :project_id }
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  # Cahier des charges V2 §4 : "Phase (conception, permis, consultation,
  # chantier, réception, après-travaux)". Suggestions pré-remplies à la
  # création d'un chantier, personnalisables ensuite — comme Lot::DEFAULT_TEMPLATE.
  DEFAULT_TEMPLATE = [
    { key: "conception", name: "Conception" },
    { key: "permis", name: "Permis" },
    { key: "consultation", name: "Consultation" },
    { key: "chantier", name: "Chantier" },
    { key: "reception", name: "Réception" },
    { key: "apres_travaux", name: "Après-travaux" }
  ].freeze

  def self.build_default_set_for(project)
    DEFAULT_TEMPLATE.map.with_index do |attrs, index|
      project.phases.build(attrs.merge(position: index))
    end
  end
end
