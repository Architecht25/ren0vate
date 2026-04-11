class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      # Identification
      t.string  :category,       null: false  # insulation | windows | heating | solar | hot_water
      t.string  :subcategory                   # toiture | murs | plancher (pour isolants)
      t.string  :name,           null: false
      t.string  :brand
      t.text    :description

      # Specs techniques (JSONB — valeurs varient par catégorie)
      t.jsonb   :technical_specs, default: {}  # lambda, r_value, uw, cop, rendement, etc.
      t.jsonb   :certifications,  default: []  # CE, ATG, EUCEB, etc.

      # Prix marché belge (€/m² ou €/unité)
      t.decimal :price_per_unit,  precision: 10, scale: 2
      t.string  :price_unit                    # m2 | unit | kWc
      t.date    :price_updated_at

      # Performance énergétique
      t.decimal :thermal_performance           # R-value ou COP ou rendement %
      t.integer :lifespan_years

      # Écologie
      t.integer :grey_energy_kwh               # Énergie grise fabrication kWh/m³
      t.boolean :recyclable,     default: false
      t.boolean :biosourced,     default: false
      t.string  :fire_class                    # A1, A2, B, C, D, E, F

      # Éligibilité primes & TVA
      t.boolean :wallonie_grant_eligible,  default: false
      t.boolean :flanders_grant_eligible,  default: false
      t.boolean :brussels_grant_eligible,  default: false
      t.boolean :vat_6_eligible,           default: false

      # Métriques
      t.integer :installations_count, default: 0
      t.decimal :average_rating,      precision: 3, scale: 1
      t.integer :reviews_count,       default: 0

      # Affichage
      t.integer :display_order, default: 0
      t.boolean :active,        default: true

      t.timestamps
    end

    add_index :products, :category
    add_index :products, [ :category, :active ]
  end
end
