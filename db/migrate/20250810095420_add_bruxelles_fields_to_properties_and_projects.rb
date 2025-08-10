class AddBruxellesFieldsToPropertiesAndProjects < ActiveRecord::Migration[8.0]
  def change
    # Champs manquants pour Properties (Bruxelles) - en évitant les doublons
    add_column :properties, :usage, :string unless column_exists?(:properties, :usage)
    # occupation existe déjà
    add_column :properties, :domiciliation, :boolean unless column_exists?(:properties, :domiciliation)
    add_column :properties, :nouvelle_construction, :boolean unless column_exists?(:properties, :nouvelle_construction)
    add_column :properties, :bien_classe, :boolean unless column_exists?(:properties, :bien_classe)
    add_column :properties, :petit_patrimoine, :boolean unless column_exists?(:properties, :petit_patrimoine)
    add_column :properties, :facade_patrimoine, :boolean unless column_exists?(:properties, :facade_patrimoine)
    add_column :properties, :surface_totale, :integer unless column_exists?(:properties, :surface_totale)
    add_column :properties, :primes_recues, :boolean unless column_exists?(:properties, :primes_recues)

    # Champs manquants pour Projects (Bruxelles)
    add_column :projects, :parties_communes, :boolean unless column_exists?(:projects, :parties_communes)
    add_column :projects, :facade_works, :boolean unless column_exists?(:projects, :facade_works)
    add_column :projects, :extension_works, :boolean unless column_exists?(:projects, :extension_works)
    add_column :projects, :toiture_modification, :boolean unless column_exists?(:projects, :toiture_modification)
    add_column :projects, :permis_urbanisme_number, :string unless column_exists?(:projects, :permis_urbanisme_number)
    add_column :projects, :permis_urbanisme_date, :date unless column_exists?(:projects, :permis_urbanisme_date)
    add_column :projects, :usage_professionnel, :boolean unless column_exists?(:projects, :usage_professionnel)
    add_column :projects, :surface_professionnelle, :integer unless column_exists?(:projects, :surface_professionnelle)
    add_column :projects, :surface_totale, :integer unless column_exists?(:projects, :surface_totale)
    add_column :projects, :previous_subsidies, :text unless column_exists?(:projects, :previous_subsidies)
  end
end
