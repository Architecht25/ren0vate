class AerDonnee < ApplicationRecord
  belongs_to :document
  belongs_to :user

  TYPES_DECLARATION = %w[isole couple isole_avec_enfant].freeze

  validates :confiance_ocr, numericality: { in: 0..100 }, allow_nil: true
  validates :type_declaration, inclusion: { in: TYPES_DECLARATION }, allow_nil: true
  validates :revenu_imposable_global, numericality: { greater_than: 0 }, allow_nil: true

  scope :extraction_validee,  -> { where(valide_manuellement: true) }
  scope :extraction_complete, -> { where(extraction_complete: true) }
  scope :annee,               ->(a) { where(annee_revenus: a.to_s) }
  scope :pour_user,           ->(u) { where(user: u) }

  def couple?
    type_declaration == 'couple'
  end

  def extraction_fiable?
    confiance_ocr && confiance_ocr >= 75
  end

  def confiance_display
    confiance_ocr ? "#{confiance_ocr.round(1)} %" : "N/A"
  end

  def revenus_menage
    return revenu_imposable_global if revenu_imposable_global.present?
    return nil unless revenu_demandeur.present?

    revenu_demandeur.to_i + revenu_conjoint.to_i
  end
end
