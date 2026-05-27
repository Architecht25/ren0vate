class AddMonumentFieldsToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :statut_patrimonial,      :string  # classé / sauvegardé / protégé / zone_protégée
    add_column :properties, :denomination_monument,   :string  # nom officiel du monument
    add_column :properties, :date_classement,         :date    # date de l'arrêté de classement
    add_column :properties, :numero_dossier_monument, :string  # référence dossier Brussels Heritage
  end
end
