class CreateDevisDonnees < ActiveRecord::Migration[8.0]
  def change
    create_table :devis_donnees do |t|
      t.references :document, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.references :property, null: true, foreign_key: true

      # ── Identification de l'entreprise ─────────────────────────────────────────
      t.string  :nom_entreprise
      t.string  :numero_bce_entreprise
      t.string  :numero_tva_entreprise

      # ── Montants ──────────────────────────────────────────────────────────────
      t.decimal :montant_total_htva, precision: 12, scale: 2
      t.decimal :montant_total_tvac, precision: 12, scale: 2
      t.decimal :taux_tva,           precision: 5,  scale: 2

      # ── Identification du devis ────────────────────────────────────────────────
      t.date    :date_devis
      t.string  :numero_devis
      t.date    :validite_devis

      # ── Travaux ────────────────────────────────────────────────────────────────
      t.jsonb   :types_travaux_detectes, default: []
      t.decimal :surface_travaux, precision: 8, scale: 2

      # ── Métadonnées OCR ────────────────────────────────────────────────────────
      t.decimal :confiance_ocr, precision: 5, scale: 2
      t.boolean :valide_manuellement, default: false, null: false
      t.boolean :extraction_complete,  default: false, null: false
      t.text    :texte_ocr_brut
      t.jsonb   :donnees_extraites, default: {}

      t.timestamps
    end

    add_index :devis_donnees, :extraction_complete
    add_index :devis_donnees, :types_travaux_detectes, using: :gin
  end
end
