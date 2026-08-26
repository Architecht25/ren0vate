class AddStatutToAuditEnergDonnees < ActiveRecord::Migration[8.0]
  def change
    # 'en_cours' | 'termine' | 'echec' — permet à l'upload de répondre immédiatement
    # pendant que le job d'extraction Claude (30-90s sur un audit complet, largement
    # au-delà des 30s de timeout du routeur Heroku) tourne en arrière-plan.
    # Les lignes déjà en base ont toutes une extraction terminée (avec ou sans succès
    # via l'ancien flux synchrone) → défaut 'termine' pour ne rien casser à l'affichage.
    add_column :audit_energ_donnees, :statut, :string, default: 'termine', null: false
  end
end
