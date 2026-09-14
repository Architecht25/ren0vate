# Ligne du plan de financement d'un chantier : fonds propres, emprunt bancaire
# classique, prêt à taux 0 régional, ou prime — comparés au coût total du projet
# (Project#total_devis_montant) pour donner une vue globale de ce qui est financé.
#
# Les lignes `prime` et `pret_taux_zero` (Wallonie) sont auto-synchronisées depuis
# Simulation/RequestProgress et PretWallonieDossier via Project#sync_financing_sources!
# (voir auto_synced?) — elles ne sont pas éditables/supprimables directement ici,
# on agit sur la simulation ou le dossier source à la place.
class FinancingSource < ApplicationRecord
  belongs_to :project
  belongs_to :simulation, optional: true
  belongs_to :pret_wallonie_dossier, optional: true

  enum :source_type, { fonds_propres: 0, emprunt_bancaire: 1, pret_taux_zero: 2, prime: 3 }
  enum :status, { simule: 0, confirme: 1, obtenu: 2 }

  SOURCE_TYPE_LABELS = {
    "fonds_propres" => "Fonds propres",
    "emprunt_bancaire" => "Emprunt bancaire",
    "pret_taux_zero" => "Prêt à taux 0",
    "prime" => "Primes"
  }.freeze

  SOURCE_TYPE_ICONS = {
    "fonds_propres" => "bi-wallet2",
    "emprunt_bancaire" => "bi-bank",
    "pret_taux_zero" => "bi-patch-check",
    "prime" => "bi-award"
  }.freeze

  STATUS_LABELS = {
    "simule" => "Simulé",
    "confirme" => "Confirmé",
    "obtenu" => "Obtenu"
  }.freeze

  # simule = juste estimé (opacité réduite dans l'UI) ; confirme/obtenu = acquis
  STATUS_COLORS = {
    "simule" => "secondary",
    "confirme" => "info",
    "obtenu" => "success"
  }.freeze

  validates :label, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :by_type, -> { order(:source_type, :label) }

  def auto_synced?
    simulation_id.present? || pret_wallonie_dossier_id.present?
  end

  def percent_of(total)
    return 0 if total.to_f.zero?

    ((amount.to_f / total.to_f) * 100).round(1)
  end
end
