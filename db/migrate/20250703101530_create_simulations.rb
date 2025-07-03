class CreateSimulations < ActiveRecord::Migration[8.0]
  def change
    create_table :simulations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.string :titre
      t.string :status
      t.string :source
      t.string :region
      t.string :user_type
      t.text :note_interne
      t.boolean :last_active_simulation
      t.datetime :completed_at
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
