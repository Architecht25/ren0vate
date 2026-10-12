# V2 — Lot 0 : périmètre de lots d'un intervenant (ProjectMember). Absence de
# ligne pour un project_member == accès à tous les lots du projet (comportement
# V1 historique, conservé comme valeur par défaut pour ne rien restreindre par
# surprise) ; présence de lignes == accès restreint à ces lots uniquement.
class CreateProjectMemberLots < ActiveRecord::Migration[8.1]
  def change
    create_table :project_member_lots do |t|
      t.references :project_member, null: false, foreign_key: true
      t.references :lot, null: false, foreign_key: true

      t.timestamps
    end

    add_index :project_member_lots, [:project_member_id, :lot_id], unique: true, name: "index_pml_on_member_and_lot"
  end
end
