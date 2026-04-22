class AerDonnee < ApplicationRecord
  belongs_to :document
  belongs_to :user

  # Chiffrement at-rest des données fiscales sensibles (RGPD A02) — 22 avril 2026
  # Les colonnes revenu_* ont été converties de decimal à text (migration 20260422100000).
  # attribute pré-déclaré pour préserver le comportement numérique (à la lecture, la valeur est un Decimal).
  # support_unencrypted_data: true permet la lecture des enregistrements antérieurs non chiffrés.
  attribute :revenu_imposable_global, :decimal, precision: 12, scale: 2
  attribute :revenu_demandeur,        :decimal, precision: 12, scale: 2
  attribute :revenu_conjoint,         :decimal, precision: 12, scale: 2

  encrypts :revenu_imposable_global, support_unencrypted_data: true
  encrypts :revenu_demandeur,        support_unencrypted_data: true
  encrypts :revenu_conjoint,         support_unencrypted_data: true
  encrypts :texte_ocr_brut,          support_unencrypted_data: true

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
