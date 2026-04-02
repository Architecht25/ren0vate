class AddDonneesExtraitesToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :donnees_extraites, :json
  end
end
