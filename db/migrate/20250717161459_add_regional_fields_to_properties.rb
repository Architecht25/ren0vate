class AddRegionalFieldsToProperties < ActiveRecord::Migration[8.0]
  def change
    # Champs spécifiques Wallonie
    add_column :properties, :type_propriete_wallonie, :string
    add_column :properties, :certificat_peb_wallonie, :string
    add_column :properties, :surface_habitable_wallonie, :integer
    add_column :properties, :mode_chauffage_wallonie, :string

    # Champs spécifiques Flandre
    add_column :properties, :type_bien_flandre, :string
    add_column :properties, :usage_flandre, :string
    add_column :properties, :chauffage_post_renovation_flandre, :string
    add_column :properties, :ean_flandre, :string
    add_column :properties, :parcelle_flandre, :string
    add_column :properties, :certificat_peb_flandre, :string

    # Champs spécifiques Bruxelles
    add_column :properties, :type_bien_bruxelles, :string
    add_column :properties, :certificat_peb_bruxelles, :string

    # Champs communs améliorés
    add_column :properties, :surface_habitable, :integer
    add_column :properties, :mode_chauffage_principal, :string
  end
end
