# V2 — Lot 4 : périmètre de lot sur les réserves (cahier des charges §4 :
# "Snag (réserve : description, photo, lot, responsable, statut,
# échéance)"). Reserve V1 avait déjà tout le reste (responsable, statut,
# date_limite="échéance", photo) — voir docs/AUDIT_V1.md §2.1, réutilisé
# tel quel plutôt que recréé, seul lot_id manquait.
class AddLotToReserves < ActiveRecord::Migration[8.1]
  def change
    add_reference :reserves, :lot, null: true, foreign_key: true
  end
end
