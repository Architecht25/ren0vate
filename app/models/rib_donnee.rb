class RibDonnee < ApplicationRecord
  belongs_to :document
  belongs_to :user

  # Chiffrement at-rest des données bancaires sensibles (RGPD A02)
  encrypts :iban
  encrypts :nom_titulaire
  # texte_ocr_brut peut contenir les coordonnées bancaires brutes de l’OCR — 22 avril 2026
  encrypts :texte_ocr_brut, support_unencrypted_data: true

  validates :iban, format: {
    with: /\ABE\d{2}\d{12}\z/,
    message: "doit être un IBAN belge valide (BE + 2 chiffres clé + 12 chiffres)"
  }, allow_blank: true
  validates :confiance_ocr, numericality: { in: 0..100 }, allow_nil: true

  scope :extraction_validee,  -> { where(valide_manuellement: true) }
  scope :extraction_complete, -> { where(extraction_complete: true) }
  scope :pour_user,           ->(u) { where(user: u) }

  # IBAN affiché au format belge groupé : BE68 5390 0754 7034
  def iban_formate
    return nil if iban.blank?

    iban.gsub(/\s/, '').scan(/.{1,4}/).join(' ')
  end

  def extraction_fiable?
    confiance_ocr && confiance_ocr >= 75
  end
end
