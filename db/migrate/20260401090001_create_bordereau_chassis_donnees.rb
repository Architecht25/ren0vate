class CreateBordereauChassisDonnees < ActiveRecord::Migration[8.0]
  def change
    create_table :bordereau_chassis_donnees do |t|
      t.references :document, null: false, foreign_key: true
      t.references :project,  null: true,  foreign_key: true

      # ── Identité du fabricant & poseur ────────────────────────────────────────
      t.string  :nom_fabricant                       # ex: Reynaers, Technal, Schüco, Veka
      t.string  :nom_poseur                          # entreprise de pose
      t.string  :numero_bce_poseur                   # N° BCE de l'installateur
      t.string  :reference_produit                   # référence commerciale du châssis

      # ── Valeurs thermiques clés (W/m²K) ──────────────────────────────────────
      t.decimal :valeur_uw, precision: 5, scale: 3   # coeff global fenêtre — seuil primes
      t.decimal :valeur_ug, precision: 5, scale: 3   # coeff vitrage
      t.decimal :valeur_uf, precision: 5, scale: 3   # coeff cadre
      t.decimal :facteur_solaire, precision: 5, scale: 3  # g-value

      # ── Caractéristiques produit ──────────────────────────────────────────────
      t.string  :type_vitrage                        # double / triple / HR++ / monolithique
      t.string  :type_chassis                        # PVC / aluminium / bois / mixte
      t.decimal :surface_totale, precision: 8, scale: 2   # m² total des châssis
      t.integer :nombre_unites                       # nombre de fenêtres / portes

      # ── Métadonnées document ──────────────────────────────────────────────────
      t.date    :date_document
      t.string  :numero_document

      # ── Éligibilité prime (calculée) ──────────────────────────────────────────
      t.boolean :eligible_prime_wallonie             # Uw ≤ 1.0 ET Ug ≤ 0.7
      t.boolean :eligible_prime_bruxelles            # Uw ≤ 1.1
      t.boolean :eligible_prime_flandre              # Uw ≤ 1.0

      # ── Champs OCR standards ─────────────────────────────────────────────────
      t.decimal :confiance_ocr, precision: 5, scale: 2, default: 0
      t.boolean :valide_manuellement, default: false
      t.boolean :extraction_complete, default: false
      t.text    :texte_ocr_brut
      t.jsonb   :donnees_extraites, default: {}

      t.timestamps
    end

    add_index :bordereau_chassis_donnees, :donnees_extraites, using: :gin
  end
end
