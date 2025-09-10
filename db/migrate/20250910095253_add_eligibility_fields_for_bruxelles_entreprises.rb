class AddEligibilityFieldsForBruxellesEntreprises < ActiveRecord::Migration[8.0]
  def change
    # Champs pour Properties (entreprises)
    add_column :properties, :comptes_annuels_conformes, :boolean, default: true, comment: "En ordre avec obligations de publication des comptes annuels"
    add_column :properties, :plan_diversite_actif, :boolean, default: false, comment: "Plan de diversité obligatoire si > 50 travailleurs"
    add_column :properties, :pourcentage_financement_public, :decimal, precision: 5, scale: 2, comment: "Pourcentage de financement public (max 75%)"

    # Champs pour Projects
    add_column :projects, :demande_avant_debut, :boolean, default: true, comment: "Demande introduite avant début de mission/investissement"
    add_column :projects, :finalite_economique_confirmee, :boolean, default: true, comment: "Finalité économique et commerciale confirmée"

    # Index pour optimiser les requêtes d'éligibilité
    add_index :properties, :comptes_annuels_conformes
    add_index :properties, :plan_diversite_actif
    add_index :projects, :demande_avant_debut
    add_index :projects, :finalite_economique_confirmee
  end
end
