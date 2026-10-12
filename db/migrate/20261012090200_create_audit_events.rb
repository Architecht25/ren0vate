# V2 — Lot 0 : journal d'audit générique, append-only (cahier des charges V2
# §6). Contrairement à Admin::AdminAuditLog (actions admin uniquement), cette
# table couvre toute validation, avenant, paiement, changement de droits et
# accès à un document sensible sur n'importe quel objet métier (polymorphe).
class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :actor, null: true, foreign_key: { to_table: :users } # nil = action système (job, webhook)
      t.references :auditable, polymorphic: true, null: false
      t.references :project, null: true, foreign_key: true # dénormalisé pour requêter "tout l'audit d'un chantier" sans traverser auditable
      t.string :action, null: false
      t.jsonb :event_data, null: false, default: {} # snapshot avant/après, métadonnées
      t.string :ip_address

      t.datetime :created_at, null: false
      # Pas d'updated_at : la table est append-only, aucune ligne n'est modifiée après création.
    end

    add_index :audit_events, [:auditable_type, :auditable_id]
    add_index :audit_events, [:project_id, :created_at]
    add_index :audit_events, :action
  end
end
