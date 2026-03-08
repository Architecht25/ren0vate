class DropSimulationPrimeCardsAndCategorieColumn < ActiveRecord::Migration[8.0]
  def change
    # Supprimer la table simulation_prime_cards (jamais utilisée - 0 enregistrements)
    drop_table :simulation_prime_cards do |t|
      t.bigint :simulation_id, null: false
      t.bigint :prime_id, null: false
      t.decimal :montant_simule
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.text :calcul_details
      t.index [:prime_id], name: "index_simulation_prime_cards_on_prime_id"
      t.index [:simulation_id], name: "index_simulation_prime_cards_on_simulation_id"
    end

    # Supprimer la colonne categorie dupliquée (category est utilisée à la place)
    remove_column :simulations, :categorie, :string
  end
end
