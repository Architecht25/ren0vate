class RemoveEntrepriseAidesTable < ActiveRecord::Migration[8.0]
  def change
    # Suppression de la table entreprise_aides
    # Cette table faisait partie du système d'aides pour entreprises de Bruxelles
    # Fonctionnalité abandonnée selon la stratégie d'évolution :
    # - Pas de modèle dans app/models
    # - Seeds pour entreprises Bruxelles supprimés
    # - Focus du projet : particuliers en Flandre

    drop_table :entreprise_aides, if_exists: true do |t|
      t.string "titre"
      t.string "slug"
      t.text "description"
      t.string "region"
      t.string "categorie"
      t.json "secteurs_eligibles"
      t.json "tailles_eligibles"
      t.decimal "montant_min"
      t.decimal "montant_max"
      t.decimal "taux_aide"
      t.json "conditions_eligibilite"
      t.json "documents_requis"
      t.string "url_officielle"
      t.string "statut"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "modalites_paiement"
      t.jsonb "delais_procedures"
    end
  end
end
