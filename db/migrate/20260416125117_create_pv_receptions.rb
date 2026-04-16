class CreatePvReceptions < ActiveRecord::Migration[8.0]
  def change
    create_table :pv_receptions do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }

      t.string   :statut,            default: "draft", null: false
      t.date     :date_reception
      t.text     :observations
      t.text     :reserves_snapshot  # JSON snapshot des réserves à la date d'envoi

      # Maître d'ouvrage (owner)
      t.string   :token_owner
      t.string   :nom_owner
      t.string   :email_owner
      t.datetime :sent_owner_at
      t.datetime :signed_owner_at
      t.text     :commentaire_owner

      # Architecte
      t.string   :token_architect
      t.string   :nom_architect
      t.string   :email_architect
      t.datetime :sent_architect_at
      t.datetime :signed_architect_at
      t.text     :commentaire_architect

      # Entrepreneur
      t.string   :token_entrepreneur
      t.string   :nom_entrepreneur
      t.string   :email_entrepreneur
      t.datetime :sent_entrepreneur_at
      t.datetime :signed_entrepreneur_at
      t.text     :commentaire_entrepreneur

      t.timestamps
    end

    add_index :pv_receptions, :token_owner,        unique: true, where: "token_owner IS NOT NULL"
    add_index :pv_receptions, :token_architect,    unique: true, where: "token_architect IS NOT NULL"
    add_index :pv_receptions, :token_entrepreneur, unique: true, where: "token_entrepreneur IS NOT NULL"
  end
end
