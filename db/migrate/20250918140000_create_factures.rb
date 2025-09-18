class CreateFactures < ActiveRecord::Migration[8.0]
  def change
    create_table :factures do |t|
      # Relations
      t.references :document, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :property, null: true, foreign_key: true

      # Données extraites par OCR
      t.decimal :montant, precision: 10, scale: 2, comment: "Montant total de la facture"
      t.string :numero_facture, comment: "Numéro de facture extrait"
      t.date :date_facture, comment: "Date de la facture"
      t.date :date_echeance, comment: "Date d'échéance si présente"

      # Type et classification
      t.string :type_facture, default: 'facture', comment: "Type: devis, facture, acompte, solde"
      t.string :statut_paiement, default: 'non_paye', comment: "Statut: non_paye, paye, partiel"

      # Données entreprise (extraites du document)
      t.string :nom_entreprise, comment: "Nom de l'entreprise facturatrice"
      t.string :numero_tva_entreprise, comment: "Numéro TVA extrait"
      t.string :numero_bce_entreprise, comment: "Numéro BCE si trouvé"

      # Détails TVA (si extraits)
      t.decimal :montant_ht, precision: 10, scale: 2, comment: "Montant hors TVA"
      t.decimal :montant_tva, precision: 10, scale: 2, comment: "Montant TVA"
      t.decimal :taux_tva, precision: 5, scale: 2, comment: "Taux TVA en %"

      # Extraction et validation
      t.decimal :confiance_ocr, precision: 5, scale: 2, comment: "Niveau de confiance OCR (0-100%)"
      t.boolean :valide_manuellement, default: false, comment: "Validé manuellement par l'utilisateur"
      t.boolean :extraction_complete, default: false, comment: "Toutes les données ont été extraites"

      # Méta-données pour alertes
      t.boolean :facture_solde, default: false, comment: "Identifiée comme facture de solde"
      t.date :date_limite_prime, comment: "Date limite calculée pour la demande de prime (date_facture + 12 mois)"
      t.integer :jours_avant_expiration, comment: "Nombre de jours avant expiration délai prime"

      # Texte OCR brut pour référence
      t.text :texte_ocr_brut, comment: "Texte complet extrait par OCR"
      t.json :donnees_extraites, comment: "Données structurées extraites en JSON"

      t.timestamps
    end

    # Index pour les requêtes fréquentes
    add_index :factures, [:project_id, :type_facture]
    add_index :factures, [:date_facture]
    add_index :factures, [:facture_solde]
    add_index :factures, [:date_limite_prime]
    add_index :factures, [:jours_avant_expiration]
    add_index :factures, [:extraction_complete]
  end
end
