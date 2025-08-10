class CreateEntrepriseAides < ActiveRecord::Migration[8.0]
  def change
    create_table :entreprise_aides do |t|
      t.string :titre
      t.string :slug
      t.text :description
      t.string :region
      t.string :categorie
      t.json :secteurs_eligibles
      t.json :tailles_eligibles
      t.decimal :montant_min
      t.decimal :montant_max
      t.decimal :taux_aide
      t.json :conditions_eligibilite
      t.json :documents_requis
      t.string :url_officielle
      t.string :statut

      t.timestamps
    end
  end
end
