class RemoveReferralsTable < ActiveRecord::Migration[8.0]
  def change
    # Suppression de la table referrals
    # Fonctionnalité de parrainage (referral program) planifiée mais jamais implémentée :
    # - Pas de modèle Referral dans app/models
    # - Pas de contrôleur
    # - Pas de relation dans User
    # - Seulement mentionnée dans les roadmaps/documents stratégiques

    drop_table :referrals, if_exists: true do |t|
      t.bigint "user_id", null: false
      t.string "email_ami"
      t.string "code"
      t.string "status"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["user_id"], name: "index_referrals_on_user_id"
    end
  end
end
