class PebDonnee < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :document, optional: true
  belongs_to :user
  belongs_to :project, optional: true

  LABELS_VALIDES = %w[A++ A+ A B C D E F G].freeze
  REGIONS_VALIDES = %w[wallonie flandre bruxelles].freeze
  PHASES_VALIDES  = %w[avant_travaux apres_travaux].freeze
  STATUTS_VALIDES = %w[en_cours termine echec].freeze

  validates :region, inclusion: { in: REGIONS_VALIDES }, allow_blank: true
  validates :label_peb, inclusion: { in: LABELS_VALIDES }, allow_blank: true
  validates :phase, inclusion: { in: PHASES_VALIDES }, allow_nil: true
  validates :statut, inclusion: { in: STATUTS_VALIDES }

  scope :recents,        -> { order(created_at: :desc) }
  scope :valides,        -> { where(extraction_complete: true) }
  scope :avant_travaux,  -> { where(phase: 'avant_travaux') }
  scope :apres_travaux,  -> { where(phase: 'apres_travaux') }

  def en_cours?
    statut == 'en_cours'
  end

  def echec?
    statut == 'echec'
  end

  def termine?
    statut == 'termine'
  end

  # ── Persistance du résultat d'extraction (partagée contrôleur ↔ job) ────────
  # Le scan étant désormais asynchrone (PebExtractionJob — le fallback OCR
  # page-par-page sur les PDFs VEKA peut dépasser les 30s de timeout du routeur
  # Heroku), cette méthode centralise le mapping résultat de service → colonnes.
  def appliquer_resultat_extraction!(result)
    update!(
      statut:              'termine',
      region:              result[:region],
      numero_certificat:   result[:numero_certificat],
      label_peb:           result[:label_peb],
      score_ep:            result[:score_ep],
      surface_reference:   result[:surface_reference],
      date_certificat:     result[:date_certificat],
      date_validite:       result[:date_validite],
      confiance_ocr:       result[:confiance_ocr],
      extraction_complete: result[:extraction_complete],
      texte_ocr_brut:      result[:texte_ocr_brut],
      donnees_extraites:   { 'recommandations' => result[:recommandations] || [] }
    )
  end

  def marquer_echec_extraction!(message = nil)
    update!(statut: 'echec', extraction_complete: false)
    Rails.logger.error("PebDonnee##{id}: échec extraction — #{message}") if message.present?
  end

  # Label PEB formaté avec couleur Bootstrap
  COULEURS_LABEL = {
    'A++' => 'success', 'A+' => 'success', 'A' => 'success',
    'B'   => 'info',
    'C'   => 'primary',
    'D'   => 'warning',
    'E'   => 'warning',
    'F'   => 'danger',
    'G'   => 'danger'
  }.freeze

  # Score numérique pour comparaison avant/après
  SCORE_LABEL = {
    'A++' => 9, 'A+' => 8, 'A' => 7, 'B' => 6, 'C' => 5,
    'D' => 4, 'E' => 3, 'F' => 2, 'G' => 1
  }.freeze

  def couleur_bootstrap
    COULEURS_LABEL.fetch(label_peb&.upcase, 'secondary')
  end

  def score_label_numerique
    SCORE_LABEL.fetch(label_peb&.upcase, 0)
  end

  def score_ep_formate
    return nil unless score_ep
    "#{score_ep.to_i} kWh/(m².an)"
  end

  def perime?
    return false unless date_validite
    date_validite < Date.today
  end

  def apres_travaux?
    phase == 'apres_travaux'
  end

  def annees_validite_restantes
    return nil unless date_validite
    ((date_validite - Date.today) / 365.25).floor
  end
end
