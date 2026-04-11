class AuditEnergDonnee < ApplicationRecord
  belongs_to :document, optional: true
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :project,  optional: true

  LABELS_VALIDES = %w[A++ A+ A B C D E F G].freeze

  validates :label_initial, inclusion: { in: LABELS_VALIDES }, allow_blank: true
  validates :label_final,   inclusion: { in: LABELS_VALIDES }, allow_blank: true

  scope :recents,  -> { order(created_at: :desc) }
  scope :valides,  -> { where(extraction_complete: true) }

  # ── Couleurs Bootstrap pour les labels ──────────────────────────────────────
  COULEURS_LABEL = {
    'A++' => 'success', 'A+' => 'success', 'A' => 'success',
    'B'   => 'info',
    'C'   => 'primary',
    'D'   => 'warning',
    'E'   => 'warning',
    'F'   => 'danger',
    'G'   => 'danger'
  }.freeze

  def couleur_label_initial
    COULEURS_LABEL.fetch(label_initial&.upcase, 'secondary')
  end

  def couleur_label_final
    COULEURS_LABEL.fetch(label_final&.upcase, 'secondary')
  end

  # ── Accesseurs sur les recommandations ──────────────────────────────────────
  # Retourne Array<HashWithIndifferentAccess> depuis le JSONB
  def recommandations
    (recommandations_json || []).map(&:with_indifferent_access)
  end

  def recommandations_bouquet(numero)
    recommandations.select { |r| r[:bouquet].to_i == numero.to_i }
  end

  def bouquets
    recommandations.map { |r| r[:bouquet].to_i }.uniq.sort
  end

  # ── Bilan global ─────────────────────────────────────────────────────────────
  def bilan
    (bilan_json || {}).with_indifferent_access
  end

  def cout_total_estime
    bilan[:cout_total].to_i
  end

  def primes_total
    bilan[:subsides_total].to_i
  end

  def gain_annuel_total
    bilan[:economie_an].to_i
  end

  def temps_retour_global
    bilan[:temps_retour]
  end

  # ── Présentation ─────────────────────────────────────────────────────────────
  def titre_court
    return "Audit #{numero_audit}" if numero_audit.present?
    "Audit énergétique du #{date_enregistrement&.strftime('%d/%m/%Y')}"
  end

  def auditeur_complet
    parts = [denomination_auditeur, numero_pae]
    parts.compact_blank.join(' — ')
  end

  def perime?
    # Un rapport d'audit logement wallonie est valable 10 ans
    return false unless date_enregistrement
    date_enregistrement < 10.years.ago.to_date
  end

  def nombre_recommandations
    recommandations.size
  end

  def nombre_bouquets
    bouquets.size
  end
end
