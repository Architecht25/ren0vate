class CreateRibDonnees < ActiveRecord::Migration[8.0]
  def up
    create_table :rib_donnees do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true

      t.string  :iban            # Ex: BE68539007547034 (normalisé sans espaces)
      t.string  :bic             # Ex: BBRUBEBB
      t.string  :nom_titulaire
      t.string  :nom_banque

      t.decimal :confiance_ocr,       precision: 5, scale: 2
      t.boolean :valide_manuellement, default: false, null: false
      t.boolean :extraction_complete, default: false, null: false
      t.text    :texte_ocr_brut
      t.jsonb   :donnees_extraites,   default: {}

      t.timestamps
    end
  end

  def down
    drop_table :rib_donnees
  end
end
