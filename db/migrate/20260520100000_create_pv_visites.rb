class CreatePvVisites < ActiveRecord::Migration[8.1]
  def change
    create_table :pv_visites do |t|
      t.references :project, null: false, foreign_key: true
      t.references :auteur,  null: false, foreign_key: { to_table: :users }
      t.integer    :numero,      null: false, default: 1
      t.date       :date_visite, null: false
      t.string     :statut,      null: false, default: "draft"
      t.text       :presents
      t.text       :observations
      t.jsonb      :points,      null: false, default: []
      t.string     :token_owner
      t.string     :token_entrepreneur

      t.timestamps
    end

    add_index :pv_visites, [:project_id, :numero], unique: true
    add_index :pv_visites, :token_owner,       unique: true, where: "token_owner IS NOT NULL"
    add_index :pv_visites, :token_entrepreneur, unique: true, where: "token_entrepreneur IS NOT NULL"
  end
end
