class DevisDonnee < ApplicationRecord
  belongs_to :document
  belongs_to :project,  optional: true
  belongs_to :property, optional: true

  # ── Catégorie de l'émetteur ──────────────────────────────────────────────────
  CATEGORIES_EMETTEUR = %w[architecte entrepreneur autre].freeze

  enum :categorie_emetteur, {
    architecte:   'architecte',
    entrepreneur: 'entrepreneur',
    autre:        'autre'
  }, prefix: :emetteur

  # ── Types de travaux reconnus ───────────────────────────────────────────────
  TYPES_TRAVAUX_VALIDES = %w[
    isolation_toit
    isolation_facade
    isolation_sol
    isolation_murs
    chassis_vitrage
    chauffage
    sanitaire
    electricite
    gaz
    maconnerie
    carrelage_revetement
    plafonnage_peinture
    toiture
    pompe_chaleur
    ventilation
    chauffe_eau_thermodynamique
    photovoltaique
    eclairage
    audit_energetique
    renovation_generale
    autre
  ].freeze

  # ── Validations ─────────────────────────────────────────────────────────────
  validates :confiance_ocr, numericality: { in: 0..100 }, allow_nil: true
  validates :montant_total_htva,
            numericality: { greater_than: 0 },
            allow_nil: true
  validates :taux_tva,
            numericality: { in: 0..100 },
            allow_nil: true

  # ── Scopes ──────────────────────────────────────────────────────────────────
  scope :extraction_validee,  -> { where(valide_manuellement: true) }
  scope :extraction_complete, -> { where(extraction_complete: true) }
  scope :pour_project,        ->(p) { where(project: p) }
  scope :avec_travaux,        ->(type) { where("types_travaux_detectes @> ?", [type].to_json) }
  scope :par_categorie,       ->(cat) { where(categorie_emetteur: cat) }
  scope :avec_montant,        -> { where.not(montant_total_htva: nil) }
  scope :with_montant,        -> { where.not(montant_total_htva: nil) }

  # ── Méthodes d'instance ────────────────────────────────────────────────────

  def extraction_fiable?
    confiance_ocr && confiance_ocr >= 75
  end

  def confiance_display
    confiance_ocr ? "#{confiance_ocr.round(1)} %" : "N/A"
  end

  def montant_htva_formate
    return nil unless montant_total_htva
    ActiveSupport::NumberHelper.number_to_currency(montant_total_htva, unit: '€', separator: ',', delimiter: '.', format: '%n %u HTVA')
  end

  def montant_tvac_formate
    return nil unless montant_total_tvac
    ActiveSupport::NumberHelper.number_to_currency(montant_total_tvac, unit: '€', separator: ',', delimiter: '.', format: '%n %u TVAC')
  end

  def date_devis_display
    date_devis&.strftime("%d/%m/%Y") || "Non extraite"
  end

  def validite_devis_display
    validite_devis&.strftime("%d/%m/%Y") || "Non précisée"
  end

  def devis_expire?
    validite_devis.present? && validite_devis < Date.current
  end

  def devis_expire_bientot?
    validite_devis.present? &&
      validite_devis >= Date.current &&
      validite_devis <= Date.current + 30.days
  end

  def types_travaux_libelles
    labels = {
      'isolation_toit'              => "Isolation toiture",
      'isolation_facade'            => "Isolation façade",
      'isolation_sol'               => "Isolation du sol",
      'isolation_murs'              => "Isolation murs int.",
      'chassis_vitrage'             => "Châssis / vitrages",
      'chauffage'                   => "Chauffage",
      'sanitaire'                   => "Sanitaire / égouttage",
      'electricite'                 => "Électricité",
      'gaz'                         => "Gaz",
      'maconnerie'                  => "Maçonnerie",
      'carrelage_revetement'        => "Carrelage / revêtement",
      'plafonnage_peinture'         => "Plafonnage / peinture",
      'toiture'                     => "Toiture / zinc",
      'pompe_chaleur'               => "Pompe à chaleur",
      'ventilation'                 => "Ventilation",
      'chauffe_eau_thermodynamique' => "Chauffe-eau thermo.",
      'photovoltaique'              => "Photovoltaïque",
      'eclairage'                   => "Éclairage",
      'audit_energetique'           => "Audit énergétique",
      'renovation_generale'         => "Rénovation générale",
      'autre'                       => "Autre"
    }
    Array(types_travaux_detectes).map { |t| labels.fetch(t, t.humanize) }
  end
end
