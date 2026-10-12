# V2 — Lot 6 : conformité et garanties (cahier des charges §4-5.E).
# ComplianceItem distinct du système de checklists V1 (ChecklistTemplate/
# ProjectChecklist) : celui-ci couvre l'inspection qualité par PHASE de
# chantier (gros œuvre, second œuvre...), ComplianceItem couvre les
# obligations légales/administratives par RÉGION (permis, PEB, attestations,
# assurances) — deux besoins différents malgré la ressemblance structurelle,
# pas de fusion.
class CreateComplianceAndWarranties < ActiveRecord::Migration[8.1]
  def change
    create_table :compliance_items do |t|
      t.references :project, null: false, foreign_key: true

      t.string :label, null: false
      t.string :region, null: false # cohérent avec SubsidyRule::REGIONS (wallonie/flandre/bruxelles)
      t.string :category, null: false # "permis" / "peb" / "attestation" / "assurance" / "reception"
      t.string :status, null: false, default: "a_faire" # a_faire / en_cours / obtenu / non_applicable
      t.date :due_date
      t.references :project_document, null: true, foreign_key: true # justificatif, si déposé

      t.timestamps
    end

    create_table :warranties do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true
      t.references :project_document, null: true, foreign_key: true # certificat/attestation de garantie, si déposé

      t.string :label, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_index :warranties, :end_date
  end
end
