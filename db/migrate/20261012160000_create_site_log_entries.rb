# V2 — Lot 4 : journal de chantier (cahier des charges §4-5.D : "SiteLogEntry
# (journal de chantier : texte, photos datées et géolocalisées)"). Nouveau —
# aucun équivalent V1 identifié dans l'audit.
class CreateSiteLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :site_log_entries do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.text :body, null: false
      t.datetime :observed_at, null: false
      t.float :latitude
      t.float :longitude

      t.timestamps
    end

    add_index :site_log_entries, [:project_id, :observed_at]
  end
end
