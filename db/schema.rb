# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_16_171636) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "code"
    t.string "description"
    t.integer "seuil_seul"
    t.integer "seuil_seul_avec_charge"
    t.integer "couple_sans_charge"
    t.integer "increment_par_personne"
    t.boolean "autre_bien_interdit"
    t.boolean "location_sociale_autorisee"
    t.boolean "eligible_pour_verbouwlening"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.bigint "request_id", null: false
    t.bigint "project_id", null: false
    t.bigint "simulation_id", null: false
    t.string "type_document"
    t.string "file_url"
    t.string "status"
    t.text "notes"
    t.string "document_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["property_id"], name: "index_documents_on_property_id"
    t.index ["request_id"], name: "index_documents_on_request_id"
    t.index ["simulation_id"], name: "index_documents_on_simulation_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "message"
    t.boolean "read"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "prime_submissions", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "user_id", null: false
    t.string "dossier_number"
    t.integer "region"
    t.integer "status"
    t.text "form_data"
    t.string "admin_reference"
    t.string "admin_status"
    t.text "admin_response_data"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_prime_submissions_on_property_id"
    t.index ["user_id"], name: "index_prime_submissions_on_user_id"
  end

  create_table "primes", force: :cascade do |t|
    t.string "slug"
    t.string "titre"
    t.string "unite"
    t.string "type_de_valeur"
    t.string "region"
    t.string "eligible_categories", default: [], array: true
    t.jsonb "valeurs_par_categorie"
    t.text "condition"
    t.text "conseil"
    t.text "document"
    t.text "specifique"
    t.jsonb "placeholder"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "categorie_limite"
    t.string "categorie_visible"
    t.string "icon_name"
    t.decimal "plafond", precision: 10, scale: 2
    t.bigint "category_id"
    t.string "groupe"
    t.integer "ordre_affichage"
    t.index ["slug"], name: "index_primes_on_slug"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "nom"
    t.text "description"
    t.string "statut"
    t.string "intervenant_entrepreneur"
    t.string "intervenant_architecte"
    t.date "date_début"
    t.date "date_fin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_projects_on_property_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "titre"
    t.string "adresse"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rue"
    t.string "numero"
    t.string "code_postal"
    t.string "commune"
    t.string "region"
    t.string "type_propriete"
    t.string "type"
    t.string "occupation"
    t.string "autre_bien"
    t.string "peb"
    t.integer "annee_construction"
    t.integer "date_raccordement_electrique"
    t.string "numero_ean"
    t.string "numero_cadastre"
    t.boolean "audit_energetique"
    t.bigint "user_id", null: false
    t.string "reconstruit"
    t.date "date_peb_avant_travaux"
    t.date "date_peb_apres_travaux"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "email_ami"
    t.string "code"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_referrals_on_user_id"
  end

  create_table "request_progresses", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "prime_id", null: false
    t.integer "pourcentage"
    t.string "step"
    t.boolean "completed"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prime_id"], name: "index_request_progresses_on_prime_id"
    t.index ["request_id"], name: "index_request_progresses_on_request_id"
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.bigint "project_id"
    t.bigint "simulation_id"
    t.float "montant_total"
    t.string "status"
    t.datetime "submitted_at"
    t.datetime "validated_at"
    t.datetime "confirmation_offre_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region"
    t.string "title"
    t.text "description"
    t.integer "revenus_menage"
    t.integer "nombre_personnes"
    t.string "type_travaux"
    t.decimal "surface_travaux", precision: 10, scale: 2
    t.decimal "cout_estime", precision: 10, scale: 2
    t.integer "revenus_reference"
    t.string "composition_menage"
    t.string "categories_travaux"
    t.boolean "logement_principal"
    t.decimal "montant_travaux", precision: 10, scale: 2
    t.integer "inkomen_gezin"
    t.string "gezinssamenstelling"
    t.string "type_renovatie"
    t.boolean "eigenaar_bewoner"
    t.decimal "kostprijs_werken", precision: 10, scale: 2
    t.boolean "domicile"
    t.string "type_demandeur"
    t.string "registre_national"
    t.string "nom"
    t.string "prenom"
    t.string "telephone"
    t.string "email"
    t.string "ean"
    t.string "parcelle"
    t.string "adresse"
    t.string "code_postal"
    t.string "commune"
    t.string "type_bien"
    t.string "usage"
    t.string "chauffage_post_renovation"
    t.boolean "travaux_toiture"
    t.boolean "travaux_murs"
    t.boolean "travaux_sol"
    t.boolean "travaux_vitrage"
    t.boolean "travaux_chauffage"
    t.boolean "travaux_complementaires"
    t.boolean "travaux_ventilation"
    t.boolean "travaux_solaire"
    t.integer "revenus_annuels"
    t.integer "personnes_charge"
    t.string "annee_aer"
    t.string "compte_bancaire"
    t.string "email_contact"
    t.string "telephone_contact"
    t.boolean "confirmation_veracite"
    t.boolean "acceptation_conditions"
    t.index ["project_id"], name: "index_requests_on_project_id"
    t.index ["property_id"], name: "index_requests_on_property_id"
    t.index ["simulation_id"], name: "index_requests_on_simulation_id"
    t.index ["user_id"], name: "index_requests_on_user_id"
  end

  create_table "simulation_prime_cards", force: :cascade do |t|
    t.bigint "simulation_id", null: false
    t.bigint "prime_id", null: false
    t.decimal "montant_simule"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prime_id"], name: "index_simulation_prime_cards_on_prime_id"
    t.index ["simulation_id"], name: "index_simulation_prime_cards_on_simulation_id"
  end

  create_table "simulations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.string "categorie"
    t.decimal "total_simule"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_simulations_on_property_id"
    t.index ["user_id"], name: "index_simulations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "nom"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "street"
    t.string "number"
    t.string "postal_code"
    t.string "city"
    t.string "region"
    t.string "iban"
    t.string "protected_client"
    t.string "situation_familiale"
    t.integer "revenu_demandeur"
    t.string "annee_revenus_demandeur"
    t.integer "revenu_conjoint"
    t.string "annee_revenus_conjoint"
    t.integer "nombre_enfants"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "works", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "surface"
    t.float "montant_estimé"
    t.string "type"
    t.bigint "prime_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prime_id"], name: "index_works_on_prime_id"
    t.index ["project_id"], name: "index_works_on_project_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "properties"
  add_foreign_key "documents", "requests"
  add_foreign_key "documents", "simulations"
  add_foreign_key "documents", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "prime_submissions", "properties"
  add_foreign_key "prime_submissions", "users"
  add_foreign_key "primes", "categories"
  add_foreign_key "projects", "properties"
  add_foreign_key "properties", "users"
  add_foreign_key "referrals", "users"
  add_foreign_key "request_progresses", "primes"
  add_foreign_key "request_progresses", "requests"
  add_foreign_key "requests", "projects"
  add_foreign_key "requests", "properties"
  add_foreign_key "requests", "simulations"
  add_foreign_key "requests", "users"
  add_foreign_key "simulation_prime_cards", "primes"
  add_foreign_key "simulation_prime_cards", "simulations"
  add_foreign_key "simulations", "properties"
  add_foreign_key "simulations", "users"
  add_foreign_key "works", "primes"
  add_foreign_key "works", "projects"
end
