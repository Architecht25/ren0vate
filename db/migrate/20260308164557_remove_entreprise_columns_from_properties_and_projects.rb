class RemoveEntrepriseColumnsFromPropertiesAndProjects < ActiveRecord::Migration[8.0]
  def change
    # Suppression des colonnes liées à la fonctionnalité "Entreprises Bruxelles" abandonnée
    # Cette fonctionnalité était destinée à gérer les aides pour entreprises à Bruxelles
    # mais a été abandonnée selon la stratégie d'évolution (focus sur particuliers en Flandre)

    # ========================================
    # TABLE PROPERTIES - 14 colonnes
    # ========================================

    # Profil et identification entreprise
    remove_column :properties, :profil_demandeur, :string
    remove_column :properties, :nombre_salaries, :integer
    remove_column :properties, :date_creation, :date

    # Adresse d'exploitation (différente du bien)
    remove_column :properties, :rue_exploitation, :string
    remove_column :properties, :numero_exploitation, :string
    remove_column :properties, :code_postal_exploitation, :string
    remove_column :properties, :commune_exploitation, :string
    remove_column :properties, :meme_adresse_exploitation, :boolean

    # Codes NACE (activité économique)
    remove_column :properties, :code_nace_1, :string
    remove_column :properties, :code_nace_2, :string
    remove_column :properties, :code_nace_3, :string
    remove_column :properties, :code_nace_4, :string
    remove_column :properties, :code_nace_5, :string

    # Règles d'éligibilité entreprises
    remove_column :properties, :regle_minimis, :boolean, default: false, null: false
    remove_column :properties, :comptes_annuels_conformes, :boolean, default: true
    remove_column :properties, :plan_diversite_actif, :boolean, default: false
    remove_column :properties, :pourcentage_financement_public, :decimal, precision: 5, scale: 2

    # ========================================
    # TABLE PROJECTS - 3 colonnes
    # ========================================

    # Finalité du projet (résidentielle vs économique)
    remove_column :projects, :finalite, :string, default: "residentielle", null: false
    remove_column :projects, :demande_avant_debut, :boolean, default: true
    remove_column :projects, :finalite_economique_confirmee, :boolean, default: true

    # Les indexes seront automatiquement supprimés avec les colonnes
  end
end
