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

ActiveRecord::Schema[8.1].define(version: 2026_10_31_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

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

  create_table "admin_audit_logs", force: :cascade do |t|
    t.integer "admin_id", null: false
    t.integer "target_user_id"
    t.string "action", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_admin_audit_logs_on_action"
    t.index ["admin_id"], name: "index_admin_audit_logs_on_admin_id"
    t.index ["created_at"], name: "index_admin_audit_logs_on_created_at"
  end

  create_table "aer_donnees", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "user_id", null: false
    t.string "annee_revenus"
    t.string "annee_exercice_imposition"
    t.text "revenu_imposable_global"
    t.text "revenu_demandeur"
    t.text "revenu_conjoint"
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

  create_table "ai_runs", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "actor_id"
    t.string "subject_type"
    t.bigint "subject_id"
    t.bigint "validated_by_id"
    t.string "function", null: false
    t.string "model", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "output", default: {}, null: false
    t.float "confidence"
    t.integer "estimated_cost_cents"
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_ai_runs_on_actor_id"
    t.index ["function"], name: "index_ai_runs_on_function"
    t.index ["project_id", "created_at"], name: "index_ai_runs_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_ai_runs_on_project_id"
    t.index ["subject_type", "subject_id"], name: "index_ai_runs_on_subject"
    t.index ["validated_by_id"], name: "index_ai_runs_on_validated_by_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "excerpt", null: false
    t.text "content", null: false
    t.string "category", default: "conseils", null: false
    t.string "meta_description"
    t.string "author", default: "L'équipe Ren0vate"
    t.integer "reading_time_minutes", default: 3
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_articles_on_category"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
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
    t.date "date_modification"
    t.date "valable_jusquau"
    t.text "adresse_bien"
    t.string "type_logement"
    t.string "annee_construction"
    t.decimal "volume_protege_m3", precision: 8, scale: 2
    t.decimal "surface_deperdition_m2", precision: 8, scale: 2
    t.decimal "surface_plancher_chauffe_m2", precision: 8, scale: 2
    t.jsonb "performance_json", default: {}, null: false
    t.jsonb "peb_projection_json", default: {}, null: false
    t.jsonb "etapes_json", default: [], null: false
    t.jsonb "alertes_json", default: [], null: false
    t.decimal "cout_total_scenario", precision: 10, scale: 2
    t.decimal "subsides_total_scenario", precision: 10, scale: 2
    t.decimal "economie_annuelle_scenario", precision: 10, scale: 2
    t.string "temps_retour_scenario"
    t.string "source_extraction", default: "ocr", null: false
    t.string "statut", default: "termine", null: false
    t.index ["document_id"], name: "index_audit_energ_donnees_on_document_id"
    t.index ["numero_audit"], name: "index_audit_energ_donnees_on_numero_audit"
    t.index ["project_id"], name: "index_audit_energ_donnees_on_project_id"
    t.index ["property_id"], name: "index_audit_energ_donnees_on_property_id"
    t.index ["recommandations_json"], name: "index_audit_energ_donnees_on_recommandations_json", using: :gin
    t.index ["user_id"], name: "index_audit_energ_donnees_on_user_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.bigint "project_id"
    t.string "action", null: false
    t.jsonb "event_data", default: {}, null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
    t.index ["project_id", "created_at"], name: "index_audit_events_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_audit_events_on_project_id"
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

  create_table "budget_lines", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.string "label", null: false
    t.decimal "montant_prevu", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_budget_lines_on_lot_id"
    t.index ["project_id"], name: "index_budget_lines_on_project_id"
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

  create_table "compliance_items", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "label", null: false
    t.string "region", null: false
    t.string "category", null: false
    t.string "status", default: "a_faire", null: false
    t.date "due_date"
    t.bigint "project_document_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_document_id"], name: "index_compliance_items_on_project_document_id"
    t.index ["project_id"], name: "index_compliance_items_on_project_id"
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
    t.jsonb "postes_json", default: [], null: false
    t.string "analyse_contenu_statut", default: "non_lancee", null: false
    t.decimal "analyse_contenu_confiance", precision: 5, scale: 2
    t.string "analyse_contenu_erreur"
    t.datetime "analyse_contenu_effectuee_at"
    t.boolean "retenu", default: false, null: false
    t.index ["analyse_contenu_statut"], name: "index_devis_donnees_on_analyse_contenu_statut"
    t.index ["categorie_emetteur"], name: "index_devis_donnees_on_categorie_emetteur"
    t.index ["document_id"], name: "index_devis_donnees_on_document_id"
    t.index ["extraction_complete"], name: "index_devis_donnees_on_extraction_complete"
    t.index ["project_id", "categorie_emetteur", "retenu"], name: "idx_on_project_id_categorie_emetteur_retenu_8e82d62af9"
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
    t.bigint "lease_id"
    t.index ["lease_id"], name: "index_documents_on_lease_id"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["property_id"], name: "index_documents_on_property_id"
    t.index ["request_id"], name: "index_documents_on_request_id"
    t.index ["simulation_id"], name: "index_documents_on_simulation_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "etat_avancement_lignes", force: :cascade do |t|
    t.bigint "etat_avancement_id", null: false
    t.string "thematique_code", null: false, comment: "Code de la thématique principale (ex: toiture, electricite)"
    t.string "thematique_label", null: false, comment: "Libellé affiché de la thématique"
    t.string "sous_secteur", comment: "Sous-secteur (ex: charpente, couverture)"
    t.string "reference", comment: "Référence poste contrat (1.1, 2.3…)"
    t.text "designation", null: false, comment: "Description du poste"
    t.string "unite", default: "forfait"
    t.decimal "quantite", precision: 10, scale: 3
    t.decimal "prix_unitaire", precision: 10, scale: 2
    t.decimal "montant_marche", precision: 12, scale: 2, comment: "Montant contractuel = qté × PU"
    t.integer "pct_cumule_precedent", default: 0, comment: "% réalisé dans les états précédents"
    t.integer "pct_cumule_actuel", default: 0, comment: "% réalisé déclaré dans cet état (saisi par entrepreneur)"
    t.decimal "montant_reclame", precision: 12, scale: 2, comment: "Montant réclamé = montant_marche × Δ% / 100"
    t.integer "position", default: 0, comment: "Ordre d'affichage"
    t.boolean "ia_suggere", default: false, comment: "Ligne proposée par l'IA (non encore validée)"
    t.string "ia_confiance", comment: "haute | moyenne | faible"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["etat_avancement_id", "position"], name: "idx_on_etat_avancement_id_position_edb49cf4ff"
    t.index ["etat_avancement_id"], name: "index_etat_avancement_lignes_on_etat_avancement_id"
    t.index ["thematique_code"], name: "index_etat_avancement_lignes_on_thematique_code"
  end

  create_table "etats_avancement", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "devis_donnee_id"
    t.integer "numero", default: 1, null: false, comment: "État n°1, n°2…"
    t.string "source_type", default: "manuel", null: false, comment: "devis_entrepreneur | metre_architecte | manuel"
    t.string "statut", default: "brouillon", null: false, comment: "brouillon | soumis | approuve | rejete"
    t.date "date_emission"
    t.date "periode_debut", comment: "Début de la période couverte par cet état"
    t.date "periode_fin", comment: "Fin de la période couverte"
    t.text "commentaire_entrepreneur"
    t.text "commentaire_architecte"
    t.decimal "montant_total_marche", precision: 12, scale: 2, comment: "Total du marché (contrat)"
    t.decimal "montant_cumule_precedent", precision: 12, scale: 2, default: "0.0", comment: "Cumul approuvé des états précédents"
    t.decimal "montant_reclame_periode", precision: 12, scale: 2, default: "0.0", comment: "Montant réclamé sur cette période (calculé)"
    t.decimal "montant_cumule_actuel", precision: 12, scale: 2, default: "0.0", comment: "Cumul actuel (précédent + période)"
    t.boolean "genere_par_ia", default: false, comment: "Architecture initiale générée par IA"
    t.text "resume_ia", comment: "Résumé textuel généré par Claude"
    t.datetime "soumis_at"
    t.datetime "approuve_at"
    t.datetime "rejete_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_etats_avancement_on_created_by_id"
    t.index ["devis_donnee_id"], name: "index_etats_avancement_on_devis_donnee_id"
    t.index ["project_id", "numero"], name: "index_etats_avancement_on_project_id_and_numero", unique: true
    t.index ["project_id"], name: "index_etats_avancement_on_project_id"
    t.index ["statut"], name: "index_etats_avancement_on_statut"
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

  create_table "financing_sources", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "simulation_id"
    t.bigint "pret_wallonie_dossier_id"
    t.string "label", null: false
    t.integer "source_type", null: false
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "rate", precision: 5, scale: 3
    t.integer "duration_months"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pret_wallonie_dossier_id"], name: "index_financing_sources_on_pret_wallonie_dossier_id"
    t.index ["project_id", "source_type"], name: "index_financing_sources_on_project_id_and_source_type"
    t.index ["project_id"], name: "index_financing_sources_on_project_id"
    t.index ["simulation_id"], name: "index_financing_sources_on_simulation_id"
  end

  create_table "intelligence_reports", force: :cascade do |t|
    t.string "week_of", null: false
    t.text "raw_content"
    t.text "analysis"
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.integer "sources_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_intelligence_reports_on_status"
    t.index ["week_of"], name: "index_intelligence_reports_on_week_of", unique: true
  end

  create_table "leases", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "tenant_id", null: false
    t.string "lease_type", default: "residence_principale", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "rent_amount", precision: 10, scale: 2, null: false
    t.decimal "charges_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "rental_guarantee_amount", precision: 10, scale: 2
    t.integer "indexation_month", default: 1
    t.string "status", default: "actif", null: false
    t.date "notice_given_at"
    t.string "notice_by"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_leases_on_property_id"
    t.index ["status"], name: "index_leases_on_status"
    t.index ["tenant_id"], name: "index_leases_on_tenant_id"
  end

  create_table "lots", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "key"], name: "index_lots_on_project_id_and_key", unique: true
    t.index ["project_id"], name: "index_lots_on_project_id"
  end

  create_table "marketing_weeks", force: :cascade do |t|
    t.string "week_of", null: false
    t.integer "article_id"
    t.text "linkedin_post"
    t.text "instagram_post"
    t.text "instagram_visual_brief"
    t.text "facebook_post"
    t.text "facebook_visual_brief"
    t.string "status", default: "draft", null: false
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_marketing_weeks_on_article_id"
    t.index ["status"], name: "index_marketing_weeks_on_status"
    t.index ["week_of"], name: "index_marketing_weeks_on_week_of", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "message_threads", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_message_threads_on_lot_id"
    t.index ["project_id"], name: "index_message_threads_on_project_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "message_thread_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["message_thread_id"], name: "index_messages_on_message_thread_id"
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

  create_table "nps_responses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "score", null: false
    t.text "comment"
    t.string "trigger", default: "day14"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_nps_responses_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "statut", default: "termine", null: false
    t.index ["document_id"], name: "index_peb_donnees_on_document_id"
    t.index ["phase"], name: "index_peb_donnees_on_phase"
    t.index ["project_id"], name: "index_peb_donnees_on_project_id"
    t.index ["property_id"], name: "index_peb_donnees_on_property_id"
    t.index ["user_id"], name: "index_peb_donnees_on_user_id"
  end

  create_table "phases", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "key"], name: "index_phases_on_project_id_and_key", unique: true
    t.index ["project_id"], name: "index_phases_on_project_id"
  end

  create_table "pret_wallonie_dossiers", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "simulation_id"
    t.bigint "user_id", null: false
    t.string "statut", default: "preparation", null: false
    t.string "label_peb_depart"
    t.string "label_peb_cible"
    t.string "label_peb_apres_travaux"
    t.decimal "montant_emprunte", precision: 10, scale: 2
    t.decimal "plafond_emprunt", precision: 10, scale: 2
    t.decimal "taux_reduction", precision: 5, scale: 4
    t.string "taux_interet"
    t.boolean "ecomateriaux", default: false
    t.date "date_depot"
    t.date "date_signature"
    t.date "date_limite_travaux"
    t.date "date_cloture"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_pret_wallonie_dossiers_on_project_id", unique: true
    t.index ["simulation_id"], name: "index_pret_wallonie_dossiers_on_simulation_id"
    t.index ["user_id"], name: "index_pret_wallonie_dossiers_on_user_id"
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

  create_table "project_amendments", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "project_quote_id"
    t.bigint "requested_by_id", null: false
    t.bigint "validated_by_id"
    t.text "motif", null: false
    t.decimal "delta_montant", precision: 10, scale: 2, null: false
    t.string "status", default: "propose", null: false
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_amendments_on_project_id"
    t.index ["project_quote_id"], name: "index_project_amendments_on_project_quote_id"
    t.index ["requested_by_id"], name: "index_project_amendments_on_requested_by_id"
    t.index ["validated_by_id"], name: "index_project_amendments_on_validated_by_id"
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

  create_table "project_document_chunks", force: :cascade do |t|
    t.bigint "project_document_version_id", null: false
    t.bigint "project_id", null: false
    t.text "content", null: false
    t.integer "chunk_index", null: false
    t.vector "embedding", limit: 1024
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_document_version_id", "chunk_index"], name: "index_chunks_on_version_and_index", unique: true
    t.index ["project_document_version_id"], name: "index_project_document_chunks_on_project_document_version_id"
    t.index ["project_id"], name: "index_project_document_chunks_on_project_id"
  end

  create_table "project_document_comments", force: :cascade do |t|
    t.bigint "project_document_id", null: false
    t.bigint "project_document_version_id"
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.jsonb "anchor", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_project_document_comments_on_author_id"
    t.index ["project_document_id"], name: "index_project_document_comments_on_project_document_id"
    t.index ["project_document_version_id"], name: "index_project_document_comments_on_project_document_version_id"
  end

  create_table "project_document_reviews", force: :cascade do |t|
    t.bigint "project_document_id", null: false
    t.bigint "project_document_version_id"
    t.bigint "reviewer_id", null: false
    t.string "status", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.index ["project_document_id"], name: "index_project_document_reviews_on_project_document_id"
    t.index ["project_document_version_id"], name: "index_project_document_reviews_on_project_document_version_id"
    t.index ["reviewer_id"], name: "index_project_document_reviews_on_reviewer_id"
  end

  create_table "project_document_shares", force: :cascade do |t|
    t.bigint "project_document_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_document_id", "user_id"], name: "index_pd_shares_on_document_and_user", unique: true
    t.index ["project_document_id"], name: "index_project_document_shares_on_project_document_id"
    t.index ["user_id"], name: "index_project_document_shares_on_user_id"
  end

  create_table "project_document_versions", force: :cascade do |t|
    t.bigint "project_document_id", null: false
    t.bigint "created_by_id", null: false
    t.integer "version_number", null: false
    t.string "sha256"
    t.string "file_name"
    t.string "content_type"
    t.bigint "byte_size"
    t.text "ocr_text"
    t.jsonb "extracted_metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_project_document_versions_on_created_by_id"
    t.index ["project_document_id", "version_number"], name: "idx_on_project_document_id_version_number_954ddd3ef6", unique: true
    t.index ["project_document_id"], name: "index_project_document_versions_on_project_document_id"
  end

  create_table "project_documents", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.bigint "phase_id"
    t.bigint "uploaded_by_id", null: false
    t.string "title", null: false
    t.string "document_type", null: false
    t.string "visibility", default: "all", null: false
    t.string "status", default: "brouillon", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "current_version_id"
    t.index ["current_version_id"], name: "index_project_documents_on_current_version_id"
    t.index ["lot_id"], name: "index_project_documents_on_lot_id"
    t.index ["phase_id"], name: "index_project_documents_on_phase_id"
    t.index ["project_id"], name: "index_project_documents_on_project_id"
    t.index ["uploaded_by_id"], name: "index_project_documents_on_uploaded_by_id"
  end

  create_table "project_member_lots", force: :cascade do |t|
    t.bigint "project_member_id", null: false
    t.bigint "lot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_project_member_lots_on_lot_id"
    t.index ["project_member_id", "lot_id"], name: "index_pml_on_member_and_lot", unique: true
    t.index ["project_member_id"], name: "index_project_member_lots_on_project_member_id"
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
    t.datetime "reminder_sent_at"
    t.index ["invite_token"], name: "index_project_members_on_invite_token", unique: true, where: "(invite_token IS NOT NULL)"
    t.index ["project_id", "user_id"], name: "index_project_members_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "project_notes", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "created_at"], name: "index_project_notes_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_project_notes_on_project_id"
  end

  create_table "project_quote_lines", force: :cascade do |t|
    t.bigint "project_quote_id", null: false
    t.string "description", null: false
    t.decimal "quantite", precision: 10, scale: 2, default: "1.0", null: false
    t.string "unite"
    t.decimal "prix_unitaire_ht", precision: 10, scale: 2, null: false
    t.decimal "montant_ht", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_quote_id"], name: "index_project_quote_lines_on_project_quote_id"
  end

  create_table "project_quotes", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.bigint "project_document_id"
    t.bigint "submitted_by_id"
    t.string "entreprise_nom"
    t.string "status", default: "brouillon", null: false
    t.decimal "montant_ht", precision: 10, scale: 2
    t.decimal "montant_tva", precision: 10, scale: 2
    t.decimal "montant_ttc", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_project_quotes_on_lot_id"
    t.index ["project_document_id"], name: "index_project_quotes_on_project_document_id"
    t.index ["project_id"], name: "index_project_quotes_on_project_id"
    t.index ["submitted_by_id"], name: "index_project_quotes_on_submitted_by_id"
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
    t.string "type_demandeur"
    t.string "statut_vente", default: "actif", null: false
    t.date "date_mise_en_vente"
    t.decimal "prix_vente_estime", precision: 12, scale: 2
    t.string "statut_patrimonial"
    t.string "denomination_monument"
    t.date "date_classement"
    t.string "numero_dossier_monument"
    t.integer "nombre_lots_copropriete"
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["statut_vente"], name: "index_properties_on_statut_vente"
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
    t.date "legal_archive_until"
    t.string "heure_reception"
    t.string "meteo"
    t.text "presents"
    t.text "absents"
    t.string "coordinateur_sps"
    t.jsonb "lots_reception", default: []
    t.string "source"
    t.index ["project_id"], name: "index_pv_receptions_on_project_id", unique: true
    t.index ["token_architect"], name: "index_pv_receptions_on_token_architect", unique: true, where: "(token_architect IS NOT NULL)"
    t.index ["token_entrepreneur"], name: "index_pv_receptions_on_token_entrepreneur", unique: true, where: "(token_entrepreneur IS NOT NULL)"
    t.index ["token_owner"], name: "index_pv_receptions_on_token_owner", unique: true, where: "(token_owner IS NOT NULL)"
  end

  create_table "pv_visites", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "auteur_id", null: false
    t.integer "numero", default: 1, null: false
    t.date "date_visite", null: false
    t.string "statut", default: "draft", null: false
    t.text "presents"
    t.text "observations"
    t.jsonb "points", default: [], null: false
    t.string "token_owner"
    t.string "token_entrepreneur"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "heure_visite"
    t.string "meteo"
    t.text "absents"
    t.string "coordinateur_sps"
    t.date "prochaine_visite"
    t.string "prochaine_visite_heure"
    t.jsonb "lots", default: [], null: false
    t.jsonb "decisions", default: [], null: false
    t.index ["auteur_id"], name: "index_pv_visites_on_auteur_id"
    t.index ["project_id", "numero"], name: "index_pv_visites_on_project_id_and_numero", unique: true
    t.index ["project_id"], name: "index_pv_visites_on_project_id"
    t.index ["token_entrepreneur"], name: "index_pv_visites_on_token_entrepreneur", unique: true, where: "(token_entrepreneur IS NOT NULL)"
    t.index ["token_owner"], name: "index_pv_visites_on_token_owner", unique: true, where: "(token_owner IS NOT NULL)"
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

  create_table "regulatory_sources", force: :cascade do |t|
    t.string "url", null: false
    t.string "label", null: false
    t.string "region"
    t.text "notes"
    t.string "last_content_hash"
    t.datetime "last_checked_at"
    t.datetime "last_changed_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_regulatory_sources_on_url", unique: true
  end

  create_table "rent_payments", force: :cascade do |t|
    t.bigint "lease_id", null: false
    t.date "due_date", null: false
    t.date "paid_date"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.string "payment_method"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_rent_payments_on_due_date"
    t.index ["lease_id"], name: "index_rent_payments_on_lease_id"
    t.index ["status"], name: "index_rent_payments_on_status"
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
    t.bigint "lot_id"
    t.index ["lot_id"], name: "index_reserves_on_lot_id"
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

  create_table "schedule_items", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.bigint "depends_on_id"
    t.string "label", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "status", default: "a_faire", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["depends_on_id"], name: "index_schedule_items_on_depends_on_id"
    t.index ["lot_id"], name: "index_schedule_items_on_lot_id"
    t.index ["project_id"], name: "index_schedule_items_on_project_id"
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
    t.string "regime", default: "primes_cash"
    t.index ["project_id"], name: "index_simulations_on_project_id"
    t.index ["property_id"], name: "index_simulations_on_property_id"
    t.index ["regime"], name: "index_simulations_on_regime"
    t.index ["user_id"], name: "index_simulations_on_user_id"
  end

  create_table "site_log_entries", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "observed_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_site_log_entries_on_author_id"
    t.index ["lot_id"], name: "index_site_log_entries_on_lot_id"
    t.index ["project_id", "observed_at"], name: "index_site_log_entries_on_project_id_and_observed_at"
    t.index ["project_id"], name: "index_site_log_entries_on_project_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  create_table "subsidy_case_results", force: :cascade do |t|
    t.bigint "subsidy_case_id", null: false
    t.bigint "subsidy_rule_id", null: false
    t.boolean "eligible", null: false
    t.decimal "amount_estimated", precision: 10, scale: 2
    t.jsonb "reasons", default: [], null: false
    t.datetime "created_at", null: false
    t.index ["subsidy_case_id"], name: "index_subsidy_case_results_on_subsidy_case_id"
    t.index ["subsidy_rule_id"], name: "index_subsidy_case_results_on_subsidy_rule_id"
  end

  create_table "subsidy_cases", force: :cascade do |t|
    t.bigint "project_id"
    t.bigint "user_id"
    t.string "region", null: false
    t.string "mode", default: "simulation", null: false
    t.jsonb "input_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "region"], name: "index_subsidy_cases_on_project_id_and_region"
    t.index ["project_id"], name: "index_subsidy_cases_on_project_id"
    t.index ["user_id"], name: "index_subsidy_cases_on_user_id"
  end

  create_table "subsidy_document_requirements", force: :cascade do |t|
    t.bigint "subsidy_rule_id", null: false
    t.string "document_type", null: false
    t.boolean "mandatory", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subsidy_rule_id"], name: "index_subsidy_document_requirements_on_subsidy_rule_id"
  end

  create_table "subsidy_rules", force: :cascade do |t|
    t.string "region", null: false
    t.string "key", null: false
    t.string "label", null: false
    t.date "valid_from", null: false
    t.date "valid_to"
    t.jsonb "conditions", default: [], null: false
    t.jsonb "amount_formula", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region", "key", "valid_from"], name: "index_subsidy_rules_on_region_and_key_and_valid_from"
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
    t.string "category", default: "general", null: false
    t.index ["user_id"], name: "index_support_tickets_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.text "national_number_ciphertext"
    t.text "notes"
    t.bigint "property_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_tenants_on_property_id"
    t.index ["user_id"], name: "index_tenants_on_user_id"
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
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "professional_type"
    t.string "referral_token"
    t.integer "user_profile", default: 0, null: false
    t.datetime "onboarding_completed_at"
    t.string "nom_cabinet"
    t.string "num_bce"
    t.datetime "last_project_alert_at"
    t.datetime "nps_prompted_at"
    t.datetime "onboarding_j1_sent_at"
    t.datetime "onboarding_j3_sent_at"
    t.datetime "onboarding_j7_sent_at"
    t.datetime "nurturing_n14_sent_at"
    t.datetime "nurturing_n30_sent_at"
    t.datetime "nurturing_n60_sent_at"
    t.boolean "primes_services_client", default: false, null: false
    t.datetime "contacted_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["preferred_locale"], name: "index_users_on_preferred_locale"
    t.index ["primes_services_client"], name: "index_users_on_primes_services_client"
    t.index ["referral_token"], name: "index_users_on_referral_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["user_profile"], name: "index_users_on_user_profile"
  end

  create_table "veille_articles", force: :cascade do |t|
    t.string "titre"
    t.string "source"
    t.date "source_date"
    t.string "region"
    t.text "themes"
    t.text "contenu"
    t.text "admin_notes"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "warranties", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "lot_id"
    t.bigint "project_document_id"
    t.string "label", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_warranties_on_end_date"
    t.index ["lot_id"], name: "index_warranties_on_lot_id"
    t.index ["project_document_id"], name: "index_warranties_on_project_document_id"
    t.index ["project_id"], name: "index_warranties_on_project_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aer_donnees", "documents"
  add_foreign_key "aer_donnees", "users"
  add_foreign_key "ai_runs", "projects"
  add_foreign_key "ai_runs", "users", column: "actor_id"
  add_foreign_key "ai_runs", "users", column: "validated_by_id"
  add_foreign_key "audit_energ_donnees", "documents"
  add_foreign_key "audit_energ_donnees", "projects", on_delete: :nullify
  add_foreign_key "audit_energ_donnees", "properties"
  add_foreign_key "audit_energ_donnees", "users"
  add_foreign_key "audit_events", "projects"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "bordereau_chassis_donnees", "documents"
  add_foreign_key "bordereau_chassis_donnees", "projects"
  add_foreign_key "budget_lines", "lots"
  add_foreign_key "budget_lines", "projects"
  add_foreign_key "chantier_analyses", "projects"
  add_foreign_key "checklist_items", "checklist_templates"
  add_foreign_key "complement_requests", "request_progresses"
  add_foreign_key "compliance_items", "project_documents"
  add_foreign_key "compliance_items", "projects"
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
  add_foreign_key "etat_avancement_lignes", "etats_avancement", column: "etat_avancement_id"
  add_foreign_key "etats_avancement", "devis_donnees"
  add_foreign_key "etats_avancement", "projects"
  add_foreign_key "etats_avancement", "users", column: "created_by_id"
  add_foreign_key "factures", "documents"
  add_foreign_key "factures", "projects"
  add_foreign_key "factures", "properties"
  add_foreign_key "financing_sources", "pret_wallonie_dossiers"
  add_foreign_key "financing_sources", "projects"
  add_foreign_key "financing_sources", "simulations"
  add_foreign_key "leases", "properties"
  add_foreign_key "leases", "tenants"
  add_foreign_key "lots", "projects"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "message_threads", "lots"
  add_foreign_key "message_threads", "projects"
  add_foreign_key "messages", "message_threads"
  add_foreign_key "messages", "users", column: "author_id"
  add_foreign_key "notifications", "projects"
  add_foreign_key "notifications", "properties"
  add_foreign_key "notifications", "simulations"
  add_foreign_key "notifications", "users"
  add_foreign_key "nps_responses", "users"
  add_foreign_key "page_visits", "users"
  add_foreign_key "peb_donnees", "documents"
  add_foreign_key "peb_donnees", "projects", on_delete: :nullify
  add_foreign_key "peb_donnees", "properties"
  add_foreign_key "peb_donnees", "users"
  add_foreign_key "phases", "projects"
  add_foreign_key "pret_wallonie_dossiers", "projects"
  add_foreign_key "pret_wallonie_dossiers", "simulations"
  add_foreign_key "pret_wallonie_dossiers", "users"
  add_foreign_key "prime_submissions", "properties"
  add_foreign_key "prime_submissions", "users"
  add_foreign_key "primes", "categories"
  add_foreign_key "project_amendments", "project_quotes"
  add_foreign_key "project_amendments", "projects"
  add_foreign_key "project_amendments", "users", column: "requested_by_id"
  add_foreign_key "project_amendments", "users", column: "validated_by_id"
  add_foreign_key "project_checklist_items", "checklist_items"
  add_foreign_key "project_checklist_items", "project_checklists"
  add_foreign_key "project_checklists", "checklist_templates"
  add_foreign_key "project_checklists", "projects"
  add_foreign_key "project_document_chunks", "project_document_versions"
  add_foreign_key "project_document_chunks", "projects"
  add_foreign_key "project_document_comments", "project_document_versions"
  add_foreign_key "project_document_comments", "project_documents"
  add_foreign_key "project_document_comments", "users", column: "author_id"
  add_foreign_key "project_document_reviews", "project_document_versions"
  add_foreign_key "project_document_reviews", "project_documents"
  add_foreign_key "project_document_reviews", "users", column: "reviewer_id"
  add_foreign_key "project_document_shares", "project_documents"
  add_foreign_key "project_document_shares", "users"
  add_foreign_key "project_document_versions", "project_documents"
  add_foreign_key "project_document_versions", "users", column: "created_by_id"
  add_foreign_key "project_documents", "lots"
  add_foreign_key "project_documents", "phases"
  add_foreign_key "project_documents", "project_document_versions", column: "current_version_id"
  add_foreign_key "project_documents", "projects"
  add_foreign_key "project_documents", "users", column: "uploaded_by_id"
  add_foreign_key "project_member_lots", "lots"
  add_foreign_key "project_member_lots", "project_members"
  add_foreign_key "project_members", "projects"
  add_foreign_key "project_members", "users"
  add_foreign_key "project_notes", "projects"
  add_foreign_key "project_quote_lines", "project_quotes"
  add_foreign_key "project_quotes", "lots"
  add_foreign_key "project_quotes", "project_documents"
  add_foreign_key "project_quotes", "projects"
  add_foreign_key "project_quotes", "users", column: "submitted_by_id"
  add_foreign_key "projects", "properties"
  add_foreign_key "projects", "users"
  add_foreign_key "properties", "users"
  add_foreign_key "pv_receptions", "projects"
  add_foreign_key "pv_visites", "projects"
  add_foreign_key "pv_visites", "users", column: "auteur_id"
  add_foreign_key "quote_items", "quotes"
  add_foreign_key "quotes", "properties"
  add_foreign_key "quotes", "users"
  add_foreign_key "rent_payments", "leases"
  add_foreign_key "request_progresses", "primes"
  add_foreign_key "request_progresses", "requests"
  add_foreign_key "requests", "projects"
  add_foreign_key "requests", "properties"
  add_foreign_key "requests", "simulations"
  add_foreign_key "requests", "users"
  add_foreign_key "reserves", "documents", column: "plan_document_id"
  add_foreign_key "reserves", "lots"
  add_foreign_key "reserves", "projects"
  add_foreign_key "rib_donnees", "documents"
  add_foreign_key "rib_donnees", "users"
  add_foreign_key "schedule_items", "lots"
  add_foreign_key "schedule_items", "projects"
  add_foreign_key "schedule_items", "schedule_items", column: "depends_on_id"
  add_foreign_key "simulations", "projects"
  add_foreign_key "simulations", "properties"
  add_foreign_key "simulations", "users"
  add_foreign_key "site_log_entries", "lots"
  add_foreign_key "site_log_entries", "projects"
  add_foreign_key "site_log_entries", "users", column: "author_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subscriptions", "users"
  add_foreign_key "subsidy_case_results", "subsidy_cases"
  add_foreign_key "subsidy_case_results", "subsidy_rules"
  add_foreign_key "subsidy_cases", "projects"
  add_foreign_key "subsidy_cases", "users"
  add_foreign_key "subsidy_document_requirements", "subsidy_rules"
  add_foreign_key "support_messages", "support_tickets"
  add_foreign_key "support_messages", "users"
  add_foreign_key "support_tickets", "users"
  add_foreign_key "tenants", "properties"
  add_foreign_key "tenants", "users"
  add_foreign_key "warranties", "lots"
  add_foreign_key "warranties", "project_documents"
  add_foreign_key "warranties", "projects"
end
