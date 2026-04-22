class EncryptAerRevenusAndOcrBrut < ActiveRecord::Migration[8.1]
  # Chiffrement at-rest (RGPD A02 / Priorité 3) — 22 avril 2026
  #
  # Périmètre :
  #   - aer_donnees : revenu_imposable_global, revenu_demandeur, revenu_conjoint (decimal → text)
  #   - aer_donnees : texte_ocr_brut (déjà text — aucun changement de colonne)
  #   - rib_donnees : texte_ocr_brut (déjà text — aucun changement de colonne)
  #
  # PostgreSQL accepte USING column::text pour convertir numeric → text sans perte.
  # Les valeurs existantes ("1234.56") sont lisibles via support_unencrypted_data: true.
  # Après migration, lancer : rails security:re_encrypt_aer_rib pour chiffrer les enregistrements existants.

  def up
    change_column :aer_donnees, :revenu_imposable_global, :text,
                  using: "revenu_imposable_global::text"
    change_column :aer_donnees, :revenu_demandeur, :text,
                  using: "revenu_demandeur::text"
    change_column :aer_donnees, :revenu_conjoint, :text,
                  using: "revenu_conjoint::text"
  end

  def down
    # ATTENTION : les données chiffrées ne peuvent pas être reconverties automatiquement.
    # Exécuter rails security:re_encrypt_aer_rib avant de rollback pour déchiffrer les valeurs.
    change_column :aer_donnees, :revenu_imposable_global, :decimal,
                  precision: 12, scale: 2,
                  using: "revenu_imposable_global::decimal"
    change_column :aer_donnees, :revenu_demandeur, :decimal,
                  precision: 12, scale: 2,
                  using: "revenu_demandeur::decimal"
    change_column :aer_donnees, :revenu_conjoint, :decimal,
                  precision: 12, scale: 2,
                  using: "revenu_conjoint::decimal"
  end
end
