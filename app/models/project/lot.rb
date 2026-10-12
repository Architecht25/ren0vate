class Lot < ApplicationRecord
  belongs_to :project
  has_many :project_member_lots, dependent: :destroy
  has_many :project_members, through: :project_member_lots
  has_many :project_documents, dependent: :nullify
  has_many :project_quotes, dependent: :nullify
  has_many :budget_lines, dependent: :nullify
  has_many :reserves, dependent: :nullify
  has_many :site_log_entries, dependent: :nullify
  has_many :message_threads, dependent: :nullify
  has_many :schedule_items, dependent: :nullify

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

  # V2 — Lot 2 : prévisionnel vs devisé (cahier des charges §5.C). "Facturé"
  # et "payé" attendent Invoice/Payment (hors scope de ce lot).
  def budget_summary
    {
      prevu: budget_lines.sum(:montant_prevu),
      devise: project_quotes.accepte.sum(:montant_ttc)
    }
  end
end
