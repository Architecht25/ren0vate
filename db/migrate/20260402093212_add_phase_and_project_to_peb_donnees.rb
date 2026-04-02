class AddPhaseAndProjectToPebDonnees < ActiveRecord::Migration[8.0]
  def change
    add_column :peb_donnees, :phase, :string, default: 'avant_travaux',
               comment: 'Phase: avant_travaux, apres_travaux'
    add_column :peb_donnees, :project_id, :bigint,
               comment: 'Projet associé (pour PEB après travaux)'
    add_index  :peb_donnees, :phase
    add_index  :peb_donnees, :project_id
    add_foreign_key :peb_donnees, :projects, column: :project_id, on_delete: :nullify
  end
end
