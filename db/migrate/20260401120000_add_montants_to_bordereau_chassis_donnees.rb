class AddMontantsToBordereauChassisDonnees < ActiveRecord::Migration[8.0]
  def change
    add_column :bordereau_chassis_donnees, :montant_htva,    :decimal, precision: 10, scale: 2
    add_column :bordereau_chassis_donnees, :montant_tvac,    :decimal, precision: 10, scale: 2
    add_column :bordereau_chassis_donnees, :taux_tva,        :decimal, precision: 5, scale: 2
    add_column :bordereau_chassis_donnees, :detail_chassis,  :jsonb, default: []
    add_index  :bordereau_chassis_donnees, :detail_chassis, using: :gin
  end
end
