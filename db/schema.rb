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

ActiveRecord::Schema[8.0].define(version: 2025_10_04_120617) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

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

  create_table "bce_activities", force: :cascade do |t|
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

  create_table "bce_addresses", force: :cascade do |t|
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

  create_table "bce_denominations", force: :cascade do |t|
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

  create_table "bce_enterprises", force: :cascade do |t|
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
    t.string "region"
    t.index ["region", "code"], name: "index_categories_on_region_and_code", unique: true
    t.index ["region"], name: "index_categories_on_region"
  end

  create_table "document_phase_statuses", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "document_phase_id", null: false
    t.integer "completion_percentage", default: 0
    t.integer "status", default: 0
    t.datetime "validated_at"
    t.bigint "validated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_phase_id"], name: "index_document_phase_statuses_on_document_phase_id"
    t.index ["property_id", "document_phase_id"], name: "index_phase_statuses_on_property_and_phase", unique: true
    t.index ["property_id"], name: "index_document_phase_statuses_on_property_id"
    t.index ["status"], name: "index_document_phase_statuses_on_status"
    t.index ["validated_by_id"], name: "index_document_phase_statuses_on_validated_by_id"
  end

  create_table "document_phases", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "icon", null: false
    t.string "color", null: false
    t.integer "position", null: false
    t.json "required_document_types", default: []
    t.json "optional_document_types", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category", default: "chantier", null: false, comment: "Type de projet: chantier ou investissement"
    t.index ["category"], name: "index_document_phases_on_category"
    t.index ["name"], name: "index_document_phases_on_name", unique: true
    t.index ["position"], name: "index_document_phases_on_position", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id"
    t.bigint "request_id"
    t.bigint "project_id"
    t.bigint "simulation_id"
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

  create_table "entreprise_aides", force: :cascade do |t|
    t.string "titre"
    t.string "slug"
    t.text "description"
    t.string "region"
    t.string "categorie"
    t.json "secteurs_eligibles"
    t.json "tailles_eligibles"
    t.decimal "montant_min"
    t.decimal "montant_max"
    t.decimal "taux_aide"
    t.json "conditions_eligibilite"
    t.json "documents_requis"
    t.string "url_officielle"
    t.string "statut"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "modalites_paiement"
    t.jsonb "delais_procedures"
  end

  create_table "factures", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "project_id", null: false
    t.bigint "property_id"
    t.decimal "montant", precision: 10, scale: 2, comment: "Montant total de la facture"
    t.string "numero_facture", comment: "Numéro de facture extrait"
    t.date "date_facture", comment: "Date de la facture"
    t.date "date_echeance", comment: "Date d'échéance si présente"
    t.string "type_facture", default: "facture", comment: "Type: devis, facture, acompte, solde"
    t.string "statut_paiement", default: "non_paye", comment: "Statut: non_paye, paye, partiel"
    t.string "nom_entreprise", comment: "Nom de l'entreprise facturatrice"
    t.string "numero_tva_entreprise", comment: "Numéro TVA extrait"
    t.string "numero_bce_entreprise", comment: "Numéro BCE si trouvé"
    t.decimal "montant_ht", precision: 10, scale: 2, comment: "Montant hors TVA"
    t.decimal "montant_tva", precision: 10, scale: 2, comment: "Montant TVA"
    t.decimal "taux_tva", precision: 5, scale: 2, comment: "Taux TVA en %"
    t.decimal "confiance_ocr", precision: 5, scale: 2, comment: "Niveau de confiance OCR (0-100%)"
    t.boolean "valide_manuellement", default: false, comment: "Validé manuellement par l'utilisateur"
    t.boolean "extraction_complete", default: false, comment: "Toutes les données ont été extraites"
    t.boolean "facture_solde", default: false, comment: "Identifiée comme facture de solde"
    t.date "date_limite_prime", comment: "Date limite calculée pour la demande de prime (date_facture + 12 mois)"
    t.integer "jours_avant_expiration", comment: "Nombre de jours avant expiration délai prime"
    t.text "texte_ocr_brut", comment: "Texte complet extrait par OCR"
    t.json "donnees_extraites", comment: "Données structurées extraites en JSON"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date_facture"], name: "index_factures_on_date_facture"
    t.index ["date_limite_prime"], name: "index_factures_on_date_limite_prime"
    t.index ["document_id"], name: "index_factures_on_document_id"
    t.index ["extraction_complete"], name: "index_factures_on_extraction_complete"
    t.index ["facture_solde"], name: "index_factures_on_facture_solde"
    t.index ["jours_avant_expiration"], name: "index_factures_on_jours_avant_expiration"
    t.index ["project_id", "type_facture"], name: "index_factures_on_project_id_and_type_facture"
    t.index ["project_id"], name: "index_factures_on_project_id"
    t.index ["property_id"], name: "index_factures_on_property_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "message"
    t.boolean "read"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "property_id"
    t.string "title"
    t.string "category"
    t.string "action_url"
    t.datetime "read_at"
    t.integer "priority"
    t.datetime "expires_at"
    t.bigint "project_id"
    t.bigint "simulation_id"
    t.index ["project_id"], name: "index_notifications_on_project_id"
    t.index ["property_id"], name: "index_notifications_on_property_id"
    t.index ["simulation_id"], name: "index_notifications_on_simulation_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "prime_document_templates", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "type_document"
    t.bigint "prime_id"
    t.boolean "is_required"
    t.string "file_url"
    t.integer "order_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commune_name"
    t.text "postal_codes"
    t.string "region"
    t.string "external_url"
    t.boolean "is_external_form", default: false
    t.text "contact_info"
    t.index ["commune_name"], name: "index_prime_document_templates_on_commune_name"
    t.index ["prime_id"], name: "index_prime_document_templates_on_prime_id"
    t.index ["region"], name: "index_prime_document_templates_on_region"
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
    t.json "statut_compatible"
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
    t.bigint "user_id", null: false
    t.string "bce_number"
    t.date "invoice_date"
    t.date "work_completion_date"
    t.text "type_travaux"
    t.boolean "reconstruction_demolition"
    t.boolean "tva_reduit_6_pourcent"
    t.boolean "parties_communes"
    t.boolean "facade_works"
    t.boolean "extension_works"
    t.boolean "toiture_modification"
    t.string "permis_urbanisme_number"
    t.date "permis_urbanisme_date"
    t.boolean "usage_professionnel"
    t.integer "surface_professionnelle"
    t.integer "surface_totale"
    t.text "previous_subsidies"
    t.string "project_type", default: "renovation"
    t.string "architecte_nom"
    t.string "architecte_prenom"
    t.string "architecte_entreprise"
    t.string "architecte_numero_ordre"
    t.string "architecte_telephone"
    t.string "architecte_email"
    t.text "architecte_adresse"
    t.text "architecte_specialites"
    t.string "entrepreneur_principal_nom"
    t.string "entrepreneur_principal_entreprise"
    t.string "entrepreneur_principal_numero_tva"
    t.string "entrepreneur_principal_telephone"
    t.string "entrepreneur_principal_email"
    t.text "entrepreneur_principal_adresse"
    t.string "entrepreneur_principal_assurance"
    t.text "entrepreneur_principal_certifications"
    t.text "corps_metiers"
    t.string "maitre_ouvrage_nom"
    t.string "maitre_ouvrage_contact"
    t.string "coordinateur_securite_nom"
    t.string "coordinateur_securite_contact"
    t.string "assurance_decennale_architecte"
    t.string "assurance_decennale_entrepreneur"
    t.text "garanties_travaux"
    t.string "numero_audit"
    t.date "date_audit"
    t.string "numero_agrement_auditeur"
    t.decimal "prix_audit", precision: 10, scale: 2
    t.string "finalite", default: "residentielle", null: false
    t.boolean "demande_avant_debut", default: true, comment: "Demande introduite avant début de mission/investissement"
    t.boolean "finalite_economique_confirmee", default: true, comment: "Finalité économique et commerciale confirmée"
    t.index ["demande_avant_debut"], name: "index_projects_on_demande_avant_debut"
    t.index ["finalite"], name: "index_projects_on_finalite"
    t.index ["finalite_economique_confirmee"], name: "index_projects_on_finalite_economique_confirmee"
    t.index ["property_id"], name: "index_projects_on_property_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
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
    t.string "type_propriete_wallonie"
    t.string "certificat_peb_wallonie"
    t.integer "surface_habitable_wallonie"
    t.string "mode_chauffage_wallonie"
    t.string "type_bien_flandre"
    t.string "usage_flandre"
    t.string "chauffage_post_renovation_flandre"
    t.string "ean_flandre"
    t.string "parcelle_flandre"
    t.string "certificat_peb_flandre"
    t.string "type_bien_bruxelles"
    t.string "certificat_peb_bruxelles"
    t.integer "surface_habitable"
    t.string "mode_chauffage_principal"
    t.integer "habitation_percentage"
    t.string "type_propriete_flandre"
    t.integer "pourcentage_propriete"
    t.boolean "domicilie_flandre"
    t.boolean "client_protege_flandre"
    t.string "usage"
    t.boolean "domiciliation"
    t.boolean "nouvelle_construction"
    t.boolean "bien_classe"
    t.boolean "petit_patrimoine"
    t.boolean "facade_patrimoine"
    t.integer "surface_totale"
    t.boolean "primes_recues"
    t.decimal "valeur_achat", precision: 10, scale: 2
    t.date "date_achat"
    t.string "profil_demandeur"
    t.integer "nombre_salaries"
    t.string "rue_exploitation"
    t.string "numero_exploitation"
    t.string "code_postal_exploitation"
    t.string "commune_exploitation"
    t.boolean "meme_adresse_exploitation"
    t.date "date_creation"
    t.string "code_nace_1"
    t.string "code_nace_2"
    t.string "code_nace_3"
    t.string "code_nace_4"
    t.string "code_nace_5"
    t.boolean "regle_minimis", default: false, null: false, comment: "L'entreprise a-t-elle reçu plus de 300.000€ d'aides de minimis sur 3 ans ?"
    t.boolean "comptes_annuels_conformes", default: true, comment: "En ordre avec obligations de publication des comptes annuels"
    t.boolean "plan_diversite_actif", default: false, comment: "Plan de diversité obligatoire si > 50 travailleurs"
    t.decimal "pourcentage_financement_public", precision: 5, scale: 2, comment: "Pourcentage de financement public (max 75%)"
    t.string "bce_number"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "geocoded_at"
    t.index ["comptes_annuels_conformes"], name: "index_properties_on_comptes_annuels_conformes"
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["plan_diversite_actif"], name: "index_properties_on_plan_diversite_actif"
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
    t.string "numero_dossier"
    t.string "email_suivi", null: false
    t.string "status_administratif", default: "en_preparation"
    t.decimal "montant_demande", precision: 10, scale: 2
    t.decimal "montant_accorde", precision: 10, scale: 2
    t.string "prime_accordee"
    t.date "date_soumission"
    t.date "date_derniere_maj"
    t.text "commentaires_admin"
    t.boolean "document_recu", default: false
    t.text "extracted_data", comment: "Données JSON extraites des documents reçus par email"
    t.datetime "email_processed_at", comment: "Date de traitement du dernier email reçu"
    t.string "document_extraction_status", default: "pending", comment: "Statut de l'extraction: pending, processing, completed, failed"
    t.index ["date_soumission"], name: "index_request_progresses_on_date_soumission"
    t.index ["document_extraction_status"], name: "index_request_progresses_on_document_extraction_status"
    t.index ["email_processed_at"], name: "index_request_progresses_on_email_processed_at"
    t.index ["email_suivi"], name: "index_request_progresses_on_email_suivi", unique: true
    t.index ["numero_dossier"], name: "index_request_progresses_on_numero_dossier", unique: true, where: "(numero_dossier IS NOT NULL)"
    t.index ["prime_id"], name: "index_request_progresses_on_prime_id"
    t.index ["request_id"], name: "index_request_progresses_on_request_id"
    t.index ["status_administratif"], name: "index_request_progresses_on_status_administratif"
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id"
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
    t.string "form_type"
    t.jsonb "form_data", default: {}
    t.string "template_version", default: "1.0"
    t.index ["form_data"], name: "index_requests_on_form_data", using: :gin
    t.index ["form_type"], name: "index_requests_on_form_type"
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
    t.text "calcul_details"
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
    t.boolean "eligible"
    t.string "category"
    t.text "category_description"
    t.text "ineligibility_reason"
    t.string "titre"
    t.string "region"
    t.text "parameters"
    t.string "source"
    t.bigint "project_id"
    t.boolean "eligible_investment"
    t.text "investment_ineligibility_reason"
    t.boolean "eligible_renolution"
    t.text "renolution_ineligibility_reason"
    t.index ["eligible_investment"], name: "index_simulations_on_eligible_investment"
    t.index ["eligible_renolution"], name: "index_simulations_on_eligible_renolution"
    t.index ["project_id"], name: "index_simulations_on_project_id"
    t.index ["property_id"], name: "index_simulations_on_property_id"
    t.index ["user_id"], name: "index_simulations_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_subscription_id"
    t.string "tier"
    t.string "status"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
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
    t.boolean "bim", default: false
    t.boolean "ris", default: false
    t.boolean "client_protege_bruxelles", default: false
    t.boolean "independant", default: false
    t.boolean "tva_deductible", default: false
    t.string "statut_professionnel"
    t.boolean "vente_prevue_5_ans", default: false
    t.boolean "consentement_controles", default: false
    t.boolean "compte_bancaire_belge", default: false
    t.string "type_demandeur"
    t.string "preferred_locale", default: "fr"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "role", default: 0, null: false
    t.string "national_number"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["preferred_locale"], name: "index_users_on_preferred_locale"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "document_phase_statuses", "document_phases"
  add_foreign_key "document_phase_statuses", "properties"
  add_foreign_key "document_phase_statuses", "users", column: "validated_by_id"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "properties"
  add_foreign_key "documents", "requests"
  add_foreign_key "documents", "simulations"
  add_foreign_key "documents", "users"
  add_foreign_key "factures", "documents"
  add_foreign_key "factures", "projects"
  add_foreign_key "factures", "properties"
  add_foreign_key "notifications", "projects"
  add_foreign_key "notifications", "properties"
  add_foreign_key "notifications", "simulations"
  add_foreign_key "notifications", "users"
  add_foreign_key "prime_document_templates", "primes"
  add_foreign_key "prime_submissions", "properties"
  add_foreign_key "prime_submissions", "users"
  add_foreign_key "primes", "categories"
  add_foreign_key "projects", "properties"
  add_foreign_key "projects", "users"
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
  add_foreign_key "simulations", "projects"
  add_foreign_key "simulations", "properties"
  add_foreign_key "simulations", "users"
  add_foreign_key "subscriptions", "users"
end
