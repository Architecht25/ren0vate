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

ActiveRecord::Schema[8.0].define(version: 2026_04_18_162952) do
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

  create_table "aer_donnees", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "user_id", null: false
    t.string "annee_revenus"
    t.string "annee_exercice_imposition"
    t.decimal "revenu_imposable_global", precision: 12, scale: 2
    t.decimal "revenu_demandeur", precision: 12, scale: 2
    t.decimal "revenu_conjoint", precision: 12, scale: 2
    t.integer "nombre_enfants_charge"
    t.string "nom_contribuable"
    t.string "prenom_contribuable"
    t.string "adresse_contribuable"
    t.date "date_enrolement"
    t.string "type_declaration"
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.boolean "valide_manuellement", default: false, null: false
    t.boolean "extraction_complete", default: false, null: false
    t.boolean "revenus_potentiellement_perimes", default: false, null: false
    t.text "texte_ocr_brut"
    t.jsonb "donnees_extraites", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_aer_donnees_on_document_id"
    t.index ["user_id", "annee_revenus"], name: "index_aer_donnees_on_user_id_and_annee_revenus"
    t.index ["user_id"], name: "index_aer_donnees_on_user_id"
  end

  create_table "audit_energ_donnees", force: :cascade do |t|
    t.bigint "document_id"
    t.bigint "user_id", null: false
    t.bigint "property_id"
    t.bigint "project_id"
    t.string "numero_audit"
    t.date "date_enregistrement"
    t.string "numero_pae"
    t.string "denomination_auditeur"
    t.text "adresse_auditeur"
    t.string "label_initial"
    t.string "label_final"
    t.jsonb "recommandations_json", default: []
    t.jsonb "bilan_json", default: {}
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.boolean "extraction_complete", default: false, null: false
    t.boolean "valide_manuellement", default: false, null: false
    t.text "texte_ocr_brut"
    t.jsonb "donnees_extraites", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_audit_energ_donnees_on_document_id"
    t.index ["numero_audit"], name: "index_audit_energ_donnees_on_numero_audit"
    t.index ["project_id"], name: "index_audit_energ_donnees_on_project_id"
    t.index ["property_id"], name: "index_audit_energ_donnees_on_property_id"
    t.index ["recommandations_json"], name: "index_audit_energ_donnees_on_recommandations_json", using: :gin
    t.index ["user_id"], name: "index_audit_energ_donnees_on_user_id"
  end

  create_table "bordereau_chassis_donnees", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "project_id"
    t.string "nom_fabricant"
    t.string "nom_poseur"
    t.string "numero_bce_poseur"
    t.string "reference_produit"
    t.decimal "valeur_uw", precision: 5, scale: 3
    t.decimal "valeur_ug", precision: 5, scale: 3
    t.decimal "valeur_uf", precision: 5, scale: 3
    t.decimal "facteur_solaire", precision: 5, scale: 3
    t.string "type_vitrage"
    t.string "type_chassis"
    t.decimal "surface_totale", precision: 8, scale: 2
    t.integer "nombre_unites"
    t.date "date_document"
    t.string "numero_document"
    t.boolean "eligible_prime_wallonie"
    t.boolean "eligible_prime_bruxelles"
    t.boolean "eligible_prime_flandre"
    t.decimal "confiance_ocr", precision: 5, scale: 2, default: "0.0"
    t.boolean "valide_manuellement", default: false
    t.boolean "extraction_complete", default: false
    t.text "texte_ocr_brut"
    t.jsonb "donnees_extraites", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "montant_htva", precision: 10, scale: 2
    t.decimal "montant_tvac", precision: 10, scale: 2
    t.decimal "taux_tva", precision: 5, scale: 2
    t.jsonb "detail_chassis", default: []
    t.index ["detail_chassis"], name: "index_bordereau_chassis_donnees_on_detail_chassis", using: :gin
    t.index ["document_id"], name: "index_bordereau_chassis_donnees_on_document_id"
    t.index ["donnees_extraites"], name: "index_bordereau_chassis_donnees_on_donnees_extraites", using: :gin
    t.index ["project_id"], name: "index_bordereau_chassis_donnees_on_project_id"
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

  create_table "chantier_analyses", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "avancement"
    t.string "phase"
    t.text "observations"
    t.text "alertes"
    t.text "prochaines_etapes"
    t.integer "photos_count"
    t.datetime "analysed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_chantier_analyses_on_project_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.bigint "checklist_template_id", null: false
    t.text "description", null: false
    t.boolean "required", default: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_template_id"], name: "index_checklist_items_on_checklist_template_id"
  end

  create_table "checklist_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "phase", null: false
    t.text "description"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "complement_requests", force: :cascade do |t|
    t.bigint "request_progress_id", null: false
    t.string "complement_type", null: false
    t.text "admin_message", null: false
    t.json "required_documents", default: []
    t.string "priority", default: "normal"
    t.date "deadline", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "expired_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.text "client_response"
    t.text "rejection_reason"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["complement_type"], name: "index_complement_requests_on_complement_type"
    t.index ["deadline"], name: "index_complement_requests_on_deadline"
    t.index ["request_progress_id", "status"], name: "index_complement_requests_on_request_progress_id_and_status"
    t.index ["request_progress_id"], name: "index_complement_requests_on_request_progress_id"
    t.index ["status"], name: "index_complement_requests_on_status"
  end

  create_table "devis_donnees", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "project_id"
    t.bigint "property_id"
    t.string "nom_entreprise"
    t.string "numero_bce_entreprise"
    t.string "numero_tva_entreprise"
    t.decimal "montant_total_htva", precision: 12, scale: 2
    t.decimal "montant_total_tvac", precision: 12, scale: 2
    t.decimal "taux_tva", precision: 5, scale: 2
    t.date "date_devis"
    t.string "numero_devis"
    t.date "validite_devis"
    t.jsonb "types_travaux_detectes", default: []
    t.decimal "surface_travaux", precision: 8, scale: 2
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.boolean "valide_manuellement", default: false, null: false
    t.boolean "extraction_complete", default: false, null: false
    t.text "texte_ocr_brut"
    t.jsonb "donnees_extraites", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "categorie_emetteur"
    t.index ["categorie_emetteur"], name: "index_devis_donnees_on_categorie_emetteur"
    t.index ["document_id"], name: "index_devis_donnees_on_document_id"
    t.index ["extraction_complete"], name: "index_devis_donnees_on_extraction_complete"
    t.index ["project_id"], name: "index_devis_donnees_on_project_id"
    t.index ["property_id"], name: "index_devis_donnees_on_property_id"
    t.index ["types_travaux_detectes"], name: "index_devis_donnees_on_types_travaux_detectes", using: :gin
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
    t.json "donnees_extraites"
    t.string "phase_chantier"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["property_id"], name: "index_documents_on_property_id"
    t.index ["request_id"], name: "index_documents_on_request_id"
    t.index ["simulation_id"], name: "index_documents_on_simulation_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
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
    t.string "type_intervenant", default: "entrepreneur", comment: "Type: architecte, entrepreneur, autre"
    t.text "adresse_entreprise", comment: "Adresse extraite par OCR"
    t.string "telephone_entreprise", comment: "Téléphone extrait par OCR"
    t.string "email_entreprise", comment: "Email extrait par OCR"
    t.datetime "validated_by_client_at"
    t.bigint "validated_by_client_id"
    t.index ["date_facture"], name: "index_factures_on_date_facture"
    t.index ["date_limite_prime"], name: "index_factures_on_date_limite_prime"
    t.index ["document_id"], name: "index_factures_on_document_id"
    t.index ["extraction_complete"], name: "index_factures_on_extraction_complete"
    t.index ["facture_solde"], name: "index_factures_on_facture_solde"
    t.index ["jours_avant_expiration"], name: "index_factures_on_jours_avant_expiration"
    t.index ["project_id", "type_facture"], name: "index_factures_on_project_id_and_type_facture"
    t.index ["project_id"], name: "index_factures_on_project_id"
    t.index ["property_id"], name: "index_factures_on_property_id"
    t.index ["type_intervenant"], name: "index_factures_on_type_intervenant"
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

  create_table "page_visits", force: :cascade do |t|
    t.string "page_name", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.text "referrer"
    t.datetime "visited_at", null: false
    t.bigint "user_id"
    t.string "session_id"
    t.string "region"
    t.string "page_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_name", "visited_at"], name: "index_page_visits_on_page_name_and_visited_at"
    t.index ["page_name"], name: "index_page_visits_on_page_name"
    t.index ["page_type"], name: "index_page_visits_on_page_type"
    t.index ["region"], name: "index_page_visits_on_region"
    t.index ["session_id"], name: "index_page_visits_on_session_id"
    t.index ["user_id"], name: "index_page_visits_on_user_id"
    t.index ["visited_at"], name: "index_page_visits_on_visited_at"
  end

  create_table "peb_donnees", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "document_id"
    t.bigint "user_id", null: false
    t.string "region"
    t.string "numero_certificat"
    t.string "label_peb"
    t.decimal "score_ep", precision: 8, scale: 2
    t.decimal "surface_reference", precision: 8, scale: 2
    t.date "date_certificat"
    t.date "date_validite"
    t.integer "confiance_ocr"
    t.boolean "valide_manuellement", default: false
    t.boolean "extraction_complete", default: false
    t.text "texte_ocr_brut"
    t.jsonb "donnees_extraites", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phase", default: "avant_travaux", comment: "Phase: avant_travaux, apres_travaux"
    t.bigint "project_id", comment: "Projet associé (pour PEB après travaux)"
    t.index ["document_id"], name: "index_peb_donnees_on_document_id"
    t.index ["phase"], name: "index_peb_donnees_on_phase"
    t.index ["project_id"], name: "index_peb_donnees_on_project_id"
    t.index ["property_id"], name: "index_peb_donnees_on_property_id"
    t.index ["user_id"], name: "index_peb_donnees_on_user_id"
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
    t.string "icon_name"
    t.decimal "plafond", precision: 10, scale: 2
    t.bigint "category_id"
    t.string "groupe"
    t.integer "ordre_affichage"
    t.json "statut_compatible"
    t.index ["slug"], name: "index_primes_on_slug"
  end

  create_table "products", force: :cascade do |t|
    t.string "category", null: false
    t.string "subcategory"
    t.string "name", null: false
    t.string "brand"
    t.text "description"
    t.jsonb "technical_specs", default: {}
    t.jsonb "certifications", default: []
    t.decimal "price_per_unit", precision: 10, scale: 2
    t.string "price_unit"
    t.date "price_updated_at"
    t.decimal "thermal_performance"
    t.integer "lifespan_years"
    t.integer "grey_energy_kwh"
    t.boolean "recyclable", default: false
    t.boolean "biosourced", default: false
    t.string "fire_class"
    t.boolean "wallonie_grant_eligible", default: false
    t.boolean "flanders_grant_eligible", default: false
    t.boolean "brussels_grant_eligible", default: false
    t.boolean "vat_6_eligible", default: false
    t.integer "installations_count", default: 0
    t.decimal "average_rating", precision: 3, scale: 1
    t.integer "reviews_count", default: 0
    t.integer "display_order", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "active"], name: "index_products_on_category_and_active"
    t.index ["category"], name: "index_products_on_category"
  end

  create_table "project_checklist_items", force: :cascade do |t|
    t.bigint "project_checklist_id", null: false
    t.bigint "checklist_item_id", null: false
    t.boolean "checked", default: false
    t.text "notes"
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_checklist_id"], name: "index_project_checklist_items_on_project_checklist_id"
  end

  create_table "project_checklists", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "checklist_template_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_template_id"], name: "index_project_checklists_on_checklist_template_id"
    t.index ["project_id"], name: "index_project_checklists_on_project_id"
  end

  create_table "project_members", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.string "status", default: "pending", null: false
    t.string "invite_token"
    t.string "invited_email"
    t.datetime "invite_sent_at"
    t.datetime "accepted_at"
    t.datetime "invite_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_token"], name: "index_project_members_on_invite_token", unique: true, where: "(invite_token IS NOT NULL)"
    t.index ["project_id", "user_id"], name: "index_project_members_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "nom"
    t.text "description"
    t.string "statut"
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
    t.text "entrepreneur_principal_certifications"
    t.text "corps_metiers"
    t.string "maitre_ouvrage_nom"
    t.string "maitre_ouvrage_contact"
    t.string "coordinateur_securite_nom"
    t.string "coordinateur_securite_contact"
    t.text "garanties_travaux"
    t.string "numero_audit"
    t.date "date_audit"
    t.string "numero_agrement_auditeur"
    t.decimal "prix_audit", precision: 10, scale: 2
    t.decimal "architecte_devis_montant", precision: 10, scale: 2
    t.decimal "contractor_devis_montant", precision: 10, scale: 2
    t.text "additional_entrepreneurs"
    t.jsonb "vision_analysis"
    t.datetime "vision_analysed_at"
    t.string "permis_urbanisme_statut"
    t.string "permis_urbanisme_autorite"
    t.text "permis_urbanisme_notes"
    t.jsonb "phases_avancement", default: {}, null: false
    t.datetime "entrepreneur_bce_verifie_at"
    t.string "entrepreneur_bce_statut"
    t.jsonb "permis_urbanisme_historique", default: [], null: false
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
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "geocoded_at"
    t.string "type_bien_wallonie"
    t.string "profil_demandeur"
    t.text "elements_petit_patrimoine"
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "pv_receptions", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "statut", default: "draft", null: false
    t.date "date_reception"
    t.text "observations"
    t.text "reserves_snapshot"
    t.string "token_owner"
    t.string "nom_owner"
    t.string "email_owner"
    t.datetime "sent_owner_at"
    t.datetime "signed_owner_at"
    t.text "commentaire_owner"
    t.string "token_architect"
    t.string "nom_architect"
    t.string "email_architect"
    t.datetime "sent_architect_at"
    t.datetime "signed_architect_at"
    t.text "commentaire_architect"
    t.string "token_entrepreneur"
    t.string "nom_entrepreneur"
    t.string "email_entrepreneur"
    t.datetime "sent_entrepreneur_at"
    t.datetime "signed_entrepreneur_at"
    t.text "commentaire_entrepreneur"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_pv_receptions_on_project_id", unique: true
    t.index ["token_architect"], name: "index_pv_receptions_on_token_architect", unique: true, where: "(token_architect IS NOT NULL)"
    t.index ["token_entrepreneur"], name: "index_pv_receptions_on_token_entrepreneur", unique: true, where: "(token_entrepreneur IS NOT NULL)"
    t.index ["token_owner"], name: "index_pv_receptions_on_token_owner", unique: true, where: "(token_owner IS NOT NULL)"
  end

  create_table "quote_items", force: :cascade do |t|
    t.bigint "quote_id", null: false
    t.string "work_type_key", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "unit", null: false
    t.decimal "unit_price_min", precision: 10, scale: 2
    t.decimal "unit_price_max", precision: 10, scale: 2
    t.decimal "total_min", precision: 10, scale: 2
    t.decimal "total_max", precision: 10, scale: 2
    t.jsonb "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "unit_price_avg", precision: 10, scale: 2
    t.decimal "total_avg", precision: 10, scale: 2
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "user_id", null: false
    t.decimal "total_min", precision: 10, scale: 2
    t.decimal "total_max", precision: 10, scale: 2
    t.integer "duration_min_days"
    t.integer "duration_max_days"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_avg", precision: 10, scale: 2
    t.integer "duration_avg_days"
    t.index ["property_id"], name: "index_quotes_on_property_id"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "request_progresses", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.bigint "prime_id"
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
    t.string "form_type"
    t.string "form_name"
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

  create_table "reserves", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.text "description"
    t.string "responsable"
    t.date "date_constat"
    t.date "date_limite"
    t.string "statut", default: "ouverte", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "pin_x"
    t.float "pin_y"
    t.bigint "plan_document_id"
    t.string "etage"
    t.index ["plan_document_id"], name: "index_reserves_on_plan_document_id"
    t.index ["project_id", "statut"], name: "index_reserves_on_project_id_and_statut"
    t.index ["project_id"], name: "index_reserves_on_project_id"
  end

  create_table "rib_donnees", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "user_id", null: false
    t.text "iban"
    t.string "bic"
    t.text "nom_titulaire"
    t.string "nom_banque"
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.boolean "valide_manuellement", default: false, null: false
    t.boolean "extraction_complete", default: false, null: false
    t.text "texte_ocr_brut"
    t.jsonb "donnees_extraites", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_rib_donnees_on_document_id"
    t.index ["user_id"], name: "index_rib_donnees_on_user_id"
  end

  create_table "simulations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
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

  create_table "support_messages", force: :cascade do |t|
    t.bigint "support_ticket_id", null: false
    t.bigint "user_id", null: false
    t.text "body"
    t.boolean "is_admin_reply"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["support_ticket_id"], name: "index_support_messages_on_support_ticket_id"
    t.index ["user_id"], name: "index_support_messages_on_user_id"
  end

  create_table "support_tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subject"
    t.string "status"
    t.string "priority"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_support_tickets_on_user_id"
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
    t.text "iban"
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
    t.text "national_number"
    t.integer "personnes_60_ans_et_plus"
    t.boolean "femme_enceinte"
    t.string "stripe_customer_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["preferred_locale"], name: "index_users_on_preferred_locale"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aer_donnees", "documents"
  add_foreign_key "aer_donnees", "users"
  add_foreign_key "audit_energ_donnees", "documents"
  add_foreign_key "audit_energ_donnees", "projects", on_delete: :nullify
  add_foreign_key "audit_energ_donnees", "properties"
  add_foreign_key "audit_energ_donnees", "users"
  add_foreign_key "bordereau_chassis_donnees", "documents"
  add_foreign_key "bordereau_chassis_donnees", "projects"
  add_foreign_key "chantier_analyses", "projects"
  add_foreign_key "checklist_items", "checklist_templates"
  add_foreign_key "complement_requests", "request_progresses"
  add_foreign_key "devis_donnees", "documents"
  add_foreign_key "devis_donnees", "projects"
  add_foreign_key "devis_donnees", "properties"
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
  add_foreign_key "page_visits", "users"
  add_foreign_key "peb_donnees", "documents"
  add_foreign_key "peb_donnees", "projects", on_delete: :nullify
  add_foreign_key "peb_donnees", "properties"
  add_foreign_key "peb_donnees", "users"
  add_foreign_key "prime_submissions", "properties"
  add_foreign_key "prime_submissions", "users"
  add_foreign_key "primes", "categories"
  add_foreign_key "project_checklist_items", "checklist_items"
  add_foreign_key "project_checklist_items", "project_checklists"
  add_foreign_key "project_checklists", "checklist_templates"
  add_foreign_key "project_checklists", "projects"
  add_foreign_key "project_members", "projects"
  add_foreign_key "project_members", "users"
  add_foreign_key "projects", "properties"
  add_foreign_key "projects", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "pv_receptions", "projects"
  add_foreign_key "quote_items", "quotes"
  add_foreign_key "quotes", "properties"
  add_foreign_key "quotes", "users"
  add_foreign_key "request_progresses", "primes"
  add_foreign_key "request_progresses", "requests"
  add_foreign_key "requests", "projects"
  add_foreign_key "requests", "properties"
  add_foreign_key "requests", "simulations"
  add_foreign_key "requests", "users"
  add_foreign_key "reserves", "documents", column: "plan_document_id"
  add_foreign_key "reserves", "projects"
  add_foreign_key "rib_donnees", "documents"
  add_foreign_key "rib_donnees", "users"
  add_foreign_key "simulations", "projects"
  add_foreign_key "simulations", "properties"
  add_foreign_key "simulations", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "support_messages", "support_tickets"
  add_foreign_key "support_messages", "users"
  add_foreign_key "support_tickets", "users"
end
