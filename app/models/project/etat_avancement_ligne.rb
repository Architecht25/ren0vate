class EtatAvancementLigne < ApplicationRecord
  belongs_to :etat_avancement, inverse_of: :lignes

  validates :designation,     presence: true
  validates :thematique_code, presence: true
  validates :thematique_label, presence: true
  validates :pct_cumule_actuel,    numericality: { in: 0..100 }
  validates :pct_cumule_precedent, numericality: { in: 0..100 }
  validate  :pct_actuel_gte_precedent

  before_save :recalculate_montant_reclame

  # ── Calculs ──────────────────────────────────────────────────────────────────
  def delta_pct
    (pct_cumule_actuel.to_i - pct_cumule_precedent.to_i).clamp(0, 100)
  end

  def recalculate_montant_reclame
    self.montant_reclame = (montant_marche.to_f * delta_pct / 100.0).round(2)
  end

  def montant_marche_calcule
    return montant_marche if montant_marche.present?
    return nil unless quantite.present? && prix_unitaire.present?
    (quantite.to_f * prix_unitaire.to_f).round(2)
  end

  def ia_confiance_label
    { 'haute' => '✅ Haute', 'moyenne' => '⚠️ Moyenne', 'faible' => '❓ Faible' }[ia_confiance] || '—'
  end

  private

  def pct_actuel_gte_precedent
    return unless pct_cumule_actuel.present? && pct_cumule_precedent.present?
    if pct_cumule_actuel.to_i < pct_cumule_precedent.to_i
      errors.add(:pct_cumule_actuel, "ne peut pas être inférieur au cumul précédent (#{pct_cumule_precedent}%)")
    end
  end
end
