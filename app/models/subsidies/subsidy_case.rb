# V2 — Lot 3 : dossier de prime (cahier des charges §9). Deux modes :
# "simulation" (public, sans compte — user_id et project_id peuvent être
# nil) et "dossier" (rattaché à un chantier, recalculé à chaque changement
# de devis/facture — voir #recalculate!, appelé explicitement, pas par un
# callback automatique, pour que le déclenchement reste visible dans le
# code qui modifie les devis plutôt que caché dans ce modèle).
class SubsidyCase < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :user, optional: true
  # delete_all, pas destroy : SubsidyCaseResult est append-only (voir son
  # before_destroy) — voir le même choix sur ProjectDocument#reviews.
  has_many :subsidy_case_results, dependent: :delete_all

  MODES = %w[simulation dossier].freeze

  validates :region, inclusion: { in: SubsidyRule::REGIONS }
  validates :mode, inclusion: { in: MODES }
  validate :dossier_mode_requires_project

  # Recalcule contre toutes les règles actives de la région, à la date
  # donnée (par défaut aujourd'hui). N'écrase jamais un résultat précédent —
  # chaque appel crée de nouvelles lignes SubsidyCaseResult, append-only
  # comme AuditEvent/ProjectDocumentReview : l'historique "qu'a-t-on annoncé
  # et quand" ne doit jamais disparaître.
  def recalculate!(as_of: Date.current)
    engine = Subsidies::RuleEngine.new(input_data)

    SubsidyRule.active_for_region(region, date: as_of).map do |rule|
      evaluation = engine.evaluate(rule)
      subsidy_case_results.create!(
        subsidy_rule: rule,
        eligible: evaluation[:eligible],
        amount_estimated: evaluation[:amount],
        reasons: evaluation[:reasons]
      )
    end
  end

  # Un résultat par règle — le plus récent calculé pour cette règle.
  def latest_results
    subsidy_case_results
      .select("DISTINCT ON (subsidy_rule_id) subsidy_case_results.*")
      .order(:subsidy_rule_id, created_at: :desc)
  end

  def total_estimated_amount
    latest_results.select(&:eligible).sum { |r| r.amount_estimated || 0 }
  end

  private

  def dossier_mode_requires_project
    errors.add(:project, "requis en mode dossier") if mode == "dossier" && project.blank?
  end
end
