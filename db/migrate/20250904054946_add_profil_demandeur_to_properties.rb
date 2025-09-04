class AddProfilDemandeurToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :profil_demandeur, :string
  end
end
