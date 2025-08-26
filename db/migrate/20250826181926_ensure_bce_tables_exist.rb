class EnsureBceTablesExist < ActiveRecord::Migration[8.0]
  def change
    # Cette migration s'assure que toutes les tables BCE existent
    # Elle ne fait quelque chose que si les tables n'existent pas

    # 1. Table bce_enterprises
    unless table_exists?(:bce_enterprises)
      create_table :bce_enterprises do |t|
        t.string :enterprise_number, null: false
        t.string :status
        t.string :juridical_situation
        t.string :type_of_enterprise
        t.string :juridical_form
        t.date :start_date
        t.timestamps
      end
      add_index :bce_enterprises, :enterprise_number, unique: true
    end

    # 2. Table bce_denominations
    unless table_exists?(:bce_denominations)
      create_table :bce_denominations do |t|
        t.references :bce_enterprise, null: false, foreign_key: true
        t.string :denomination, null: false
        t.string :type_denomination
        t.string :language
        t.timestamps
      end
    end

    # 3. Table bce_addresses
    unless table_exists?(:bce_addresses)
      create_table :bce_addresses do |t|
        t.references :bce_enterprise, null: false, foreign_key: true
        t.string :type_address
        t.string :country_nl
        t.string :country_fr
        t.string :zipcode
        t.string :municipality_nl
        t.string :municipality_fr
        t.string :street_nl
        t.string :street_fr
        t.string :house_number
        t.string :box
        t.timestamps
      end
    end

    # 4. Table bce_activities
    unless table_exists?(:bce_activities)
      create_table :bce_activities do |t|
        t.references :bce_enterprise, null: false, foreign_key: true
        t.string :activity_group
        t.string :nace_version
        t.string :nace_code
        t.string :classification
        t.timestamps
      end
    end

    # Ajouter les index seulement s'ils n'existent pas
    unless index_exists?(:bce_enterprises, :status)
      add_index :bce_enterprises, :status
    end

    unless index_exists?(:bce_enterprises, :juridical_form)
      add_index :bce_enterprises, :juridical_form
    end

    unless index_exists?(:bce_activities, :nace_code)
      add_index :bce_activities, :nace_code
    end
  end
end
