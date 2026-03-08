class RemoveObsoleteBceTables < ActiveRecord::Migration[8.0]
  def change
    # Suppression des tables BCE obsolètes
    # Ces tables faisaient partie d'un système d'import de données BCE pour les entreprises
    # de Bruxelles qui a été abandonné selon la stratégie d'évolution du projet
    # (focus sur particuliers Flandre, pas entreprises Bruxelles)

    drop_table :bce_activities, if_exists: true do |t|
      t.string "entity_number", null: false
      t.string "activity_group"
      t.string "nace_version"
      t.string "nace_code"
      t.string "classification"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["entity_number"], name: "index_bce_activities_on_entity_number"
      t.index ["nace_code"], name: "index_bce_activities_on_nace_code"
    end

    drop_table :bce_addresses, if_exists: true do |t|
      t.string "entity_number", null: false
      t.string "type_of_address"
      t.string "country_nl"
      t.string "country_fr"
      t.string "zipcode"
      t.string "municipality_nl"
      t.string "municipality_fr"
      t.string "street_nl"
      t.string "street_fr"
      t.string "house_number"
      t.string "box"
      t.string "extra_address_info"
      t.date "date_striking_off"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["entity_number"], name: "index_bce_addresses_on_entity_number"
      t.index ["municipality_nl", "municipality_fr"], name: "index_bce_addresses_on_municipality_nl_and_municipality_fr"
      t.index ["zipcode"], name: "index_bce_addresses_on_zipcode"
    end

    drop_table :bce_denominations, if_exists: true do |t|
      t.string "entity_number", null: false
      t.string "language"
      t.string "type_of_denomination"
      t.text "denomination", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["denomination"], name: "index_bce_denominations_on_denomination"
      t.index ["entity_number", "language"], name: "index_bce_denominations_on_entity_number_and_language"
      t.index ["entity_number"], name: "index_bce_denominations_on_entity_number"
    end

    drop_table :bce_enterprises, if_exists: true do |t|
      t.string "enterprise_number", null: false
      t.string "status"
      t.string "juridical_situation"
      t.string "type_of_enterprise"
      t.string "juridical_form"
      t.string "juridical_form_cac"
      t.date "start_date"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["enterprise_number"], name: "index_bce_enterprises_on_enterprise_number", unique: true
      t.index ["juridical_form"], name: "index_bce_enterprises_on_juridical_form"
      t.index ["status"], name: "index_bce_enterprises_on_status"
      t.index ["type_of_enterprise"], name: "index_bce_enterprises_on_type_of_enterprise"
    end
  end
end
