class CreatePebDonnees < ActiveRecord::Migration[8.0]
  def up
    create_table :peb_donnees do |t|
      t.references :property,  null: false, foreign_key: true
      t.references :document,  null: true,  foreign_key: true
      t.references :user,      null: false, foreign_key: true

      # Région détectée automatiquement
      t.string  :region                     # wallonie | flandre | bruxelles

      # 6 champs extraits
      t.string  :numero_certificat
      t.string  :label_peb                  # A++ … G
      t.decimal :score_ep, precision: 8, scale: 2   # kWh/(m².an)
      t.decimal :surface_reference, precision: 8, scale: 2  # m²
      t.date    :date_certificat
      t.date    :date_validite

      # Métadonnées OCR
      t.integer :confiance_ocr
      t.boolean :valide_manuellement, default: false
      t.boolean :extraction_complete,  default: false
      t.text    :texte_ocr_brut
      t.jsonb   :donnees_extraites,    default: {}

      t.timestamps
    end
  end

  def down
    drop_table :peb_donnees
  end
end
