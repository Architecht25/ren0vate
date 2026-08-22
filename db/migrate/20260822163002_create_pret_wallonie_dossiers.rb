class CreatePretWallonieDossiers < ActiveRecord::Migration[8.1]
  def change
    create_table :pret_wallonie_dossiers do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.references :simulation, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :statut, null: false, default: "preparation"
      t.string :label_peb_depart
      t.string :label_peb_cible
      t.string :label_peb_apres_travaux
      t.decimal :montant_emprunte, precision: 10, scale: 2
      t.decimal :plafond_emprunt, precision: 10, scale: 2
      t.decimal :taux_reduction, precision: 5, scale: 4
      t.string :taux_interet
      t.boolean :ecomateriaux, default: false
      t.date :date_depot
      t.date :date_signature
      t.date :date_limite_travaux
      t.date :date_cloture
      t.text :notes

      t.timestamps
    end
  end
end
