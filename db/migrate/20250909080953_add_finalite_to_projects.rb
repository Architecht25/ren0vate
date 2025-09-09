class AddFinaliteToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :finalite, :string, default: 'residentielle', null: false
    add_index :projects, :finalite

    # Commentaire pour clarification
    # Valeurs possibles: 'residentielle', 'economique'
    # - residentielle: affiche uniquement cartes RENOLUTION
    # - economique: affiche cartes investissements + cartes RENOLUTION
  end
end
