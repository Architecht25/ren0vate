# V2 — Lot 6 : obligation légale/administrative par région (cahier des
# charges §5.E : "Checklist d'obligations par projet et par région").
# Distinct de ChecklistTemplate V1 (inspection qualité par phase) — voir
# le commentaire de la migration.
class ComplianceItem < ApplicationRecord
  belongs_to :project
  belongs_to :project_document, optional: true

  REGIONS = %w[wallonie flandre bruxelles].freeze
  CATEGORIES = %w[permis peb attestation assurance reception].freeze

  enum :status, { a_faire: "a_faire", en_cours: "en_cours", obtenu: "obtenu", non_applicable: "non_applicable" }, default: "a_faire"

  validates :label, presence: true
  validates :region, inclusion: { in: REGIONS }
  validates :category, inclusion: { in: CATEGORIES }

  scope :outstanding, -> { where.not(status: %w[obtenu non_applicable]) }

  def overdue?
    due_date.present? && due_date.past? && !obtenu? && !non_applicable?
  end
end
