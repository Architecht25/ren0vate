class CreateAerDonnees < ActiveRecord::Migration[8.0]
  def up
    create_table :aer_donnees do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true

      t.string  :annee_revenus
      t.string  :annee_exercice_imposition
      t.integer :revenu_imposable_global
      t.integer :revenu_demandeur
      t.integer :revenu_conjoint
      t.integer :nombre_enfants_charge
      t.string  :nom_contribuable
      t.string  :prenom_contribuable
      t.string  :adresse_contribuable
      t.date    :date_enrolement
      t.string  :type_declaration
      t.decimal :confiance_ocr,                   precision: 5, scale: 2
      t.boolean :valide_manuellement,             default: false, null: false
      t.boolean :extraction_complete,             default: false, null: false
      t.boolean :revenus_potentiellement_perimes, default: false, null: false
      t.text    :texte_ocr_brut
      t.jsonb   :donnees_extraites,               default: {}

      t.timestamps
    end

    add_index :aer_donnees, [:user_id, :annee_revenus]
  end

  def down
    drop_table :aer_donnees
  end
end
