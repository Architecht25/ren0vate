class AddPhaseChantierToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :phase_chantier, :string
  end
end
