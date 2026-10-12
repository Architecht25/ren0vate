# V2 — Lot 2 : devis structuré (cahier des charges §4). Les montants sont
# recalculés depuis les lignes (jamais saisis indépendamment) pour qu'un
# total affiché corresponde toujours à la somme réelle des postes.
class ProjectQuote < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true
  belongs_to :project_document, optional: true
  belongs_to :submitted_by, class_name: "User", optional: true

  has_many :lines, class_name: "ProjectQuoteLine", dependent: :destroy, inverse_of: :project_quote
  accepts_nested_attributes_for :lines, allow_destroy: true

  TVA_RATE = 0.21 # Belgique — taux standard. Le taux réduit 6% (rénovation résidentielle >10 ans) est une donnée à saisir par devis, pas câblée en dur ici pour le MVP.

  enum :status, { brouillon: "brouillon", envoye: "envoye", accepte: "accepte", refuse: "refuse" }, default: "brouillon"

  validate :lot_belongs_to_project

  before_save :recompute_totals

  def recompute_totals
    self.montant_ht = lines.reject(&:marked_for_destruction?).sum { |l| l.montant_ht || 0 }
    self.montant_tva = (montant_ht * TVA_RATE).round(2)
    self.montant_ttc = montant_ht + montant_tva
  end

  private

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end
end
