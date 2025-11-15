class CreatePageVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :page_visits do |t|
      t.string :page_name, null: false
      t.string :ip_address
      t.text :user_agent
      t.text :referrer
      t.datetime :visited_at, null: false
      t.references :user, null: true, foreign_key: true  # null: true pour les visiteurs anonymes
      t.string :session_id  # Pour tracker les sessions anonymes
      t.string :region      # Bruxelles, Wallonie, Flandre
      t.string :page_type   # simulation, entreprise, particulier, etc.

      t.timestamps
    end

    add_index :page_visits, :page_name
    add_index :page_visits, :visited_at
    add_index :page_visits, :session_id
    add_index :page_visits, :region
    add_index :page_visits, :page_type
    add_index :page_visits, [:page_name, :visited_at]
  end
end
