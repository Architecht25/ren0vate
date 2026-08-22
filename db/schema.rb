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

ActiveRecord::Schema[8.1].define(version: 2026_08_22_163002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.integer "admin_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.text "metadata"
    t.integer "target_user_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["action"], name: "index_admin_audit_logs_on_action"
    t.index ["admin_id"], name: "index_admin_audit_logs_on_admin_id"
    t.index ["created_at"], name: "index_admin_audit_logs_on_created_at"
  end

  create_table "aer_donnees", force: :cascade do |t|
    t.string "adresse_contribuable"
    t.string "annee_exercice_imposition"
    t.string "annee_revenus"
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.date "date_enrolement"
    t.bigint "document_id", null: false
    t.jsonb "donnees_extraites", default: {}
    t.boolean "extraction_complete", default: false, null: false
    t.string "nom_contribuable"
    t.integer "nombre_enfants_charge"
    t.string "prenom_contribuable"
    t.text "revenu_conjoint"
    t.text "revenu_demandeur"
    t.text "revenu_imposable_global"
    t.boolean "revenus_potentiellement_perimes", default: false, null: false
    t.text "texte_ocr_brut"
    t.string "type_declaration"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "valide_manuellement", default: false, null: false
    t.index ["document_id"], name: "index_aer_donnees_on_document_id"
    t.index ["user_id", "annee_revenus"], name: "index_aer_donnees_on_user_id_and_annee_revenus"
    t.index ["user_id"], name: "index_aer_donnees_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "author", default: "L'équipe Ren0vate"
    t.string "category", default: "conseils", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.text "excerpt", null: false
    t.string "meta_description"
    t.datetime "published_at"
    t.integer "reading_time_minutes", default: 3
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_articles_on_category"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "audit_energ_donnees", force: :cascade do |t|
    t.text "adresse_auditeur"
    t.jsonb "bilan_json", default: {}
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.date "date_enregistrement"
    t.string "denomination_auditeur"
    t.bigint "document_id"
    t.jsonb "donnees_extraites", default: {}
    t.boolean "extraction_complete", default: false, null: false
    t.string "label_final"
    t.string "label_initial"
    t.string "numero_audit"
    t.string "numero_pae"
    t.bigint "project_id"
    t.bigint "property_id"
    t.jsonb "recommandations_json", default: []
    t.text "texte_ocr_brut"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "valide_manuellement", default: false, null: false
    t.index ["document_id"], name: "index_audit_energ_donnees_on_document_id"
    t.index ["numero_audit"], name: "index_audit_energ_donnees_on_numero_audit"
    t.index ["project_id"], name: "index_audit_energ_donnees_on_project_id"
    t.index ["property_id"], name: "index_audit_energ_donnees_on_property_id"
    t.index ["recommandations_json"], name: "index_audit_energ_donnees_on_recommandations_json", using: :gin
    t.index ["user_id"], name: "index_audit_energ_donnees_on_user_id"
  end

  create_table "bordereau_chassis_donnees", force: :cascade do |t|
    t.decimal "confiance_ocr", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.date "date_document"
    t.jsonb "detail_chassis", default: []
    t.bigint "document_id", null: false
    t.jsonb "donnees_extraites", default: {}
    t.boolean "eligible_prime_bruxelles"
    t.boolean "eligible_prime_flandre"
    t.boolean "eligible_prime_wallonie"
    t.boolean "extraction_complete", default: false
    t.decimal "facteur_solaire", precision: 5, scale: 3
    t.decimal "montant_htva", precision: 10, scale: 2
    t.decimal "montant_tvac", precision: 10, scale: 2
    t.string "nom_fabricant"
    t.string "nom_poseur"
    t.integer "nombre_unites"
    t.string "numero_bce_poseur"
    t.string "numero_document"
    t.bigint "project_id"
    t.string "reference_produit"
    t.decimal "surface_totale", precision: 8, scale: 2
    t.decimal "taux_tva", precision: 5, scale: 2
    t.text "texte_ocr_brut"
    t.string "type_chassis"
    t.string "type_vitrage"
    t.datetime "updated_at", null: false
    t.decimal "valeur_uf", precision: 5, scale: 3
    t.decimal "valeur_ug", precision: 5, scale: 3
    t.decimal "valeur_uw", precision: 5, scale: 3
    t.boolean "valide_manuellement", default: false
    t.index ["detail_chassis"], name: "index_bordereau_chassis_donnees_on_detail_chassis", using: :gin
    t.index ["document_id"], name: "index_bordereau_chassis_donnees_on_document_id"
    t.index ["donnees_extraites"], name: "index_bordereau_chassis_donnees_on_donnees_extraites", using: :gin
    t.index ["project_id"], name: "index_bordereau_chassis_donnees_on_project_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "autre_bien_interdit"
    t.string "code"
    t.integer "couple_sans_charge"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "eligible_pour_verbouwlening"
    t.integer "increment_par_personne"
    t.boolean "location_sociale_autorisee"
    t.string "region"
    t.integer "seuil_seul"
    t.integer "seuil_seul_avec_charge"
    t.datetime "updated_at", null: false
    t.index ["region", "code"], name: "index_categories_on_region_and_code", unique: true
    t.index ["region"], name: "index_categories_on_region"
  end

  create_table "chantier_analyses", force: :cascade do |t|
    t.text "alertes"
    t.datetime "analysed_at"
    t.integer "avancement"
    t.datetime "created_at", null: false
    t.text "observations"
    t.string "phase"
    t.integer "photos_count"
    t.text "prochaines_etapes"
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_chantier_analyses_on_project_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.bigint "checklist_template_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "position", default: 0
    t.boolean "required", default: false
    t.datetime "updated_at", null: false
    t.index ["checklist_template_id"], name: "index_checklist_items_on_checklist_template_id"
  end

  create_table "checklist_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "phase", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "complement_requests", force: :cascade do |t|
    t.text "admin_message", null: false
    t.datetime "approved_at"
    t.text "client_response"
    t.string "complement_type", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "deadline", null: false
    t.datetime "expired_at"
    t.string "priority", default: "normal"
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.bigint "request_progress_id", null: false
    t.json "required_documents", default: []
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["complement_type"], name: "index_complement_requests_on_complement_type"
    t.index ["deadline"], name: "index_complement_requests_on_deadline"
    t.index ["request_progress_id", "status"], name: "index_complement_requests_on_request_progress_id_and_status"
    t.index ["request_progress_id"], name: "index_complement_requests_on_request_progress_id"
    t.index ["status"], name: "index_complement_requests_on_status"
  end

  create_table "devis_donnees", force: :cascade do |t|
    t.string "categorie_emetteur"
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.date "date_devis"
    t.bigint "document_id", null: false
    t.jsonb "donnees_extraites", default: {}
    t.boolean "extraction_complete", default: false, null: false
    t.decimal "montant_total_htva", precision: 12, scale: 2
    t.decimal "montant_total_tvac", precision: 12, scale: 2
    t.string "nom_entreprise"
    t.string "numero_bce_entreprise"
    t.string "numero_devis"
    t.string "numero_tva_entreprise"
    t.bigint "project_id"
    t.bigint "property_id"
    t.decimal "surface_travaux", precision: 8, scale: 2
    t.decimal "taux_tva", precision: 5, scale: 2
    t.text "texte_ocr_brut"
    t.jsonb "types_travaux_detectes", default: []
    t.datetime "updated_at", null: false
    t.boolean "valide_manuellement", default: false, null: false
    t.date "validite_devis"
    t.index ["categorie_emetteur"], name: "index_devis_donnees_on_categorie_emetteur"
    t.index ["document_id"], name: "index_devis_donnees_on_document_id"
    t.index ["extraction_complete"], name: "index_devis_donnees_on_extraction_complete"
    t.index ["project_id"], name: "index_devis_donnees_on_project_id"
    t.index ["property_id"], name: "index_devis_donnees_on_property_id"
    t.index ["types_travaux_detectes"], name: "index_devis_donnees_on_types_travaux_detectes", using: :gin
  end

  create_table "document_phase_statuses", force: :cascade do |t|
    t.integer "completion_percentage", default: 0
    t.datetime "created_at", null: false
    t.bigint "document_phase_id", null: false
    t.bigint "property_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.datetime "validated_at"
    t.bigint "validated_by_id"
    t.index ["document_phase_id"], name: "index_document_phase_statuses_on_document_phase_id"
    t.index ["property_id", "document_phase_id"], name: "index_phase_statuses_on_property_and_phase", unique: true
    t.index ["property_id"], name: "index_document_phase_statuses_on_property_id"
    t.index ["status"], name: "index_document_phase_statuses_on_status"
    t.index ["validated_by_id"], name: "index_document_phase_statuses_on_validated_by_id"
  end

  create_table "document_phases", force: :cascade do |t|
    t.string "category", default: "chantier", null: false, comment: "Type de projet: chantier ou investissement"
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "icon", null: false
    t.string "name", null: false
    t.json "optional_document_types", default: []
    t.integer "position", null: false
    t.json "required_document_types", default: []
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_document_phases_on_category"
    t.index ["name"], name: "index_document_phases_on_name", unique: true
    t.index ["position"], name: "index_document_phases_on_position", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_source"
    t.json "donnees_extraites"
    t.string "file_url"
    t.bigint "lease_id"
    t.text "notes"
    t.string "phase_chantier"
    t.bigint "project_id"
    t.bigint "property_id"
    t.bigint "request_id"
    t.bigint "simulation_id"
    t.string "status"
    t.string "type_document"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["lease_id"], name: "index_documents_on_lease_id"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["property_id"], name: "index_documents_on_property_id"
    t.index ["request_id"], name: "index_documents_on_request_id"
    t.index ["simulation_id"], name: "index_documents_on_simulation_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "etat_avancement_lignes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "designation", null: false, comment: "Description du poste"
    t.bigint "etat_avancement_id", null: false
    t.string "ia_confiance", comment: "haute | moyenne | faible"
    t.boolean "ia_suggere", default: false, comment: "Ligne proposée par l'IA (non encore validée)"
    t.decimal "montant_marche", precision: 12, scale: 2, comment: "Montant contractuel = qté × PU"
    t.decimal "montant_reclame", precision: 12, scale: 2, comment: "Montant réclamé = montant_marche × Δ% / 100"
    t.integer "pct_cumule_actuel", default: 0, comment: "% réalisé déclaré dans cet état (saisi par entrepreneur)"
    t.integer "pct_cumule_precedent", default: 0, comment: "% réalisé dans les états précédents"
    t.integer "position", default: 0, comment: "Ordre d'affichage"
    t.decimal "prix_unitaire", precision: 10, scale: 2
    t.decimal "quantite", precision: 10, scale: 3
    t.string "reference", comment: "Référence poste contrat (1.1, 2.3…)"
    t.string "sous_secteur", comment: "Sous-secteur (ex: charpente, couverture)"
    t.string "thematique_code", null: false, comment: "Code de la thématique principale (ex: toiture, electricite)"
    t.string "thematique_label", null: false, comment: "Libellé affiché de la thématique"
    t.string "unite", default: "forfait"
    t.datetime "updated_at", null: false
    t.index ["etat_avancement_id", "position"], name: "idx_on_etat_avancement_id_position_edb49cf4ff"
    t.index ["etat_avancement_id"], name: "index_etat_avancement_lignes_on_etat_avancement_id"
    t.index ["thematique_code"], name: "index_etat_avancement_lignes_on_thematique_code"
  end

  create_table "etats_avancement", force: :cascade do |t|
    t.datetime "approuve_at"
    t.text "commentaire_architecte"
    t.text "commentaire_entrepreneur"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.date "date_emission"
    t.bigint "devis_donnee_id"
    t.boolean "genere_par_ia", default: false, comment: "Architecture initiale générée par IA"
    t.decimal "montant_cumule_actuel", precision: 12, scale: 2, default: "0.0", comment: "Cumul actuel (précédent + période)"
    t.decimal "montant_cumule_precedent", precision: 12, scale: 2, default: "0.0", comment: "Cumul approuvé des états précédents"
    t.decimal "montant_reclame_periode", precision: 12, scale: 2, default: "0.0", comment: "Montant réclamé sur cette période (calculé)"
    t.decimal "montant_total_marche", precision: 12, scale: 2, comment: "Total du marché (contrat)"
    t.integer "numero", default: 1, null: false, comment: "État n°1, n°2…"
    t.date "periode_debut", comment: "Début de la période couverte par cet état"
    t.date "periode_fin", comment: "Fin de la période couverte"
    t.bigint "project_id", null: false
    t.datetime "rejete_at"
    t.text "resume_ia", comment: "Résumé textuel généré par Claude"
    t.datetime "soumis_at"
    t.string "source_type", default: "manuel", null: false, comment: "devis_entrepreneur | metre_architecte | manuel"
    t.string "statut", default: "brouillon", null: false, comment: "brouillon | soumis | approuve | rejete"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_etats_avancement_on_created_by_id"
    t.index ["devis_donnee_id"], name: "index_etats_avancement_on_devis_donnee_id"
    t.index ["project_id", "numero"], name: "index_etats_avancement_on_project_id_and_numero", unique: true
    t.index ["project_id"], name: "index_etats_avancement_on_project_id"
    t.index ["statut"], name: "index_etats_avancement_on_statut"
  end

  create_table "factures", force: :cascade do |t|
    t.text "adresse_entreprise", comment: "Adresse extraite par OCR"
    t.decimal "confiance_ocr", precision: 5, scale: 2, comment: "Niveau de confiance OCR (0-100%)"
    t.datetime "created_at", null: false
    t.date "date_echeance", comment: "Date d'échéance si présente"
    t.date "date_facture", comment: "Date de la facture"
    t.date "date_limite_prime", comment: "Date limite calculée pour la demande de prime (date_facture + 12 mois)"
    t.bigint "document_id", null: false
    t.json "donnees_extraites", comment: "Données structurées extraites en JSON"
    t.string "email_entreprise", comment: "Email extrait par OCR"
    t.boolean "extraction_complete", default: false, comment: "Toutes les données ont été extraites"
    t.boolean "facture_solde", default: false, comment: "Identifiée comme facture de solde"
    t.integer "jours_avant_expiration", comment: "Nombre de jours avant expiration délai prime"
    t.decimal "montant", precision: 10, scale: 2, comment: "Montant total de la facture"
    t.decimal "montant_ht", precision: 10, scale: 2, comment: "Montant hors TVA"
    t.decimal "montant_tva", precision: 10, scale: 2, comment: "Montant TVA"
    t.string "nom_entreprise", comment: "Nom de l'entreprise facturatrice"
    t.string "numero_bce_entreprise", comment: "Numéro BCE si trouvé"
    t.string "numero_facture", comment: "Numéro de facture extrait"
    t.string "numero_tva_entreprise", comment: "Numéro TVA extrait"
    t.bigint "project_id", null: false
    t.bigint "property_id"
    t.string "statut_paiement", default: "non_paye", comment: "Statut: non_paye, paye, partiel"
    t.decimal "taux_tva", precision: 5, scale: 2, comment: "Taux TVA en %"
    t.string "telephone_entreprise", comment: "Téléphone extrait par OCR"
    t.text "texte_ocr_brut", comment: "Texte complet extrait par OCR"
    t.string "type_facture", default: "facture", comment: "Type: devis, facture, acompte, solde"
    t.string "type_intervenant", default: "entrepreneur", comment: "Type: architecte, entrepreneur, autre"
    t.datetime "updated_at", null: false
    t.datetime "validated_by_client_at"
    t.bigint "validated_by_client_id"
    t.boolean "valide_manuellement", default: false, comment: "Validé manuellement par l'utilisateur"
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

  create_table "intelligence_reports", force: :cascade do |t|
    t.text "analysis"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.text "raw_content"
    t.integer "sources_count", default: 0
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "week_of", null: false
    t.index ["status"], name: "index_intelligence_reports_on_status"
    t.index ["week_of"], name: "index_intelligence_reports_on_week_of", unique: true
  end

  create_table "leases", force: :cascade do |t|
    t.decimal "charges_amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.integer "indexation_month", default: 1
    t.string "lease_type", default: "residence_principale", null: false
    t.text "notes"
    t.string "notice_by"
    t.date "notice_given_at"
    t.bigint "property_id", null: false
    t.decimal "rent_amount", precision: 10, scale: 2, null: false
    t.decimal "rental_guarantee_amount", precision: 10, scale: 2
    t.date "start_date", null: false
    t.string "status", default: "actif", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_leases_on_property_id"
    t.index ["status"], name: "index_leases_on_status"
    t.index ["tenant_id"], name: "index_leases_on_tenant_id"
  end

  create_table "marketing_weeks", force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", null: false
    t.text "facebook_post"
    t.text "facebook_visual_brief"
    t.datetime "generated_at"
    t.text "instagram_post"
    t.text "instagram_visual_brief"
    t.text "linkedin_post"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "week_of", null: false
    t.index ["article_id"], name: "index_marketing_weeks_on_article_id"
    t.index ["status"], name: "index_marketing_weeks_on_status"
    t.index ["week_of"], name: "index_marketing_weeks_on_week_of", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action_url"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "message"
    t.integer "priority"
    t.bigint "project_id"
    t.bigint "property_id"
    t.boolean "read"
    t.datetime "read_at"
    t.bigint "simulation_id"
    t.string "title"
    t.string "type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_notifications_on_project_id"
    t.index ["property_id"], name: "index_notifications_on_property_id"
    t.index ["simulation_id"], name: "index_notifications_on_simulation_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "nps_responses", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "score", null: false
    t.string "trigger", default: "day14"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_nps_responses_on_user_id"
  end

  create_table "page_visits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "page_name", null: false
    t.string "page_type"
    t.text "referrer"
    t.string "region"
    t.string "session_id"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id"
    t.datetime "visited_at", null: false
    t.index ["page_name", "visited_at"], name: "index_page_visits_on_page_name_and_visited_at"
    t.index ["page_name"], name: "index_page_visits_on_page_name"
    t.index ["page_type"], name: "index_page_visits_on_page_type"
    t.index ["region"], name: "index_page_visits_on_region"
    t.index ["session_id"], name: "index_page_visits_on_session_id"
    t.index ["user_id"], name: "index_page_visits_on_user_id"
    t.index ["visited_at"], name: "index_page_visits_on_visited_at"
  end

  create_table "peb_donnees", force: :cascade do |t|
    t.integer "confiance_ocr"
    t.datetime "created_at", null: false
    t.date "date_certificat"
    t.date "date_validite"
    t.bigint "document_id"
    t.jsonb "donnees_extraites", default: {}
    t.boolean "extraction_complete", default: false
    t.string "label_peb"
    t.string "numero_certificat"
    t.string "phase", default: "avant_travaux", comment: "Phase: avant_travaux, apres_travaux"
    t.bigint "project_id", comment: "Projet associé (pour PEB après travaux)"
    t.bigint "property_id", null: false
    t.string "region"
    t.decimal "score_ep", precision: 8, scale: 2
    t.decimal "surface_reference", precision: 8, scale: 2
    t.text "texte_ocr_brut"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "valide_manuellement", default: false
    t.index ["document_id"], name: "index_peb_donnees_on_document_id"
    t.index ["phase"], name: "index_peb_donnees_on_phase"
    t.index ["project_id"], name: "index_peb_donnees_on_project_id"
    t.index ["property_id"], name: "index_peb_donnees_on_property_id"
    t.index ["user_id"], name: "index_peb_donnees_on_user_id"
  end

  create_table "pret_wallonie_dossiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_cloture"
    t.date "date_depot"
    t.date "date_limite_travaux"
    t.date "date_signature"
    t.boolean "ecomateriaux", default: false
    t.string "label_peb_apres_travaux"
    t.string "label_peb_cible"
    t.string "label_peb_depart"
    t.decimal "montant_emprunte", precision: 10, scale: 2
    t.text "notes"
    t.decimal "plafond_emprunt", precision: 10, scale: 2
    t.bigint "project_id", null: false
    t.bigint "simulation_id"
    t.string "statut", default: "preparation", null: false
    t.string "taux_interet"
    t.decimal "taux_reduction", precision: 5, scale: 4
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_pret_wallonie_dossiers_on_project_id", unique: true
    t.index ["simulation_id"], name: "index_pret_wallonie_dossiers_on_simulation_id"
    t.index ["user_id"], name: "index_pret_wallonie_dossiers_on_user_id"
  end

  create_table "prime_submissions", force: :cascade do |t|
    t.string "admin_reference"
    t.text "admin_response_data"
    t.string "admin_status"
    t.datetime "created_at", null: false
    t.string "dossier_number"
    t.text "form_data"
    t.bigint "property_id", null: false
    t.integer "region"
    t.integer "status"
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["property_id"], name: "index_prime_submissions_on_property_id"
    t.index ["user_id"], name: "index_prime_submissions_on_user_id"
  end

  create_table "primes", force: :cascade do |t|
    t.string "categorie_limite"
    t.bigint "category_id"
    t.text "condition"
    t.text "conseil"
    t.datetime "created_at", null: false
    t.text "document"
    t.string "eligible_categories", default: [], array: true
    t.string "groupe"
    t.string "icon_name"
    t.string "image"
    t.integer "ordre_affichage"
    t.jsonb "placeholder"
    t.decimal "plafond", precision: 10, scale: 2
    t.string "region"
    t.string "slug"
    t.text "specifique"
    t.json "statut_compatible"
    t.string "titre"
    t.string "type_de_valeur"
    t.string "unite"
    t.datetime "updated_at", null: false
    t.jsonb "valeurs_par_categorie"
    t.index ["slug"], name: "index_primes_on_slug"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true
    t.decimal "average_rating", precision: 3, scale: 1
    t.boolean "biosourced", default: false
    t.string "brand"
    t.boolean "brussels_grant_eligible", default: false
    t.string "category", null: false
    t.jsonb "certifications", default: []
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0
    t.string "fire_class"
    t.boolean "flanders_grant_eligible", default: false
    t.integer "grey_energy_kwh"
    t.integer "installations_count", default: 0
    t.integer "lifespan_years"
    t.string "name", null: false
    t.decimal "price_per_unit", precision: 10, scale: 2
    t.string "price_unit"
    t.date "price_updated_at"
    t.boolean "recyclable", default: false
    t.integer "reviews_count", default: 0
    t.string "subcategory"
    t.jsonb "technical_specs", default: {}
    t.decimal "thermal_performance"
    t.datetime "updated_at", null: false
    t.boolean "vat_6_eligible", default: false
    t.boolean "wallonie_grant_eligible", default: false
    t.index ["category", "active"], name: "index_products_on_category_and_active"
    t.index ["category"], name: "index_products_on_category"
  end

  create_table "project_checklist_items", force: :cascade do |t|
    t.boolean "checked", default: false
    t.datetime "checked_at"
    t.bigint "checklist_item_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "project_checklist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_checklist_id"], name: "index_project_checklist_items_on_project_checklist_id"
  end

  create_table "project_checklists", force: :cascade do |t|
    t.bigint "checklist_template_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_template_id"], name: "index_project_checklists_on_checklist_template_id"
    t.index ["project_id"], name: "index_project_checklists_on_project_id"
  end

  create_table "project_members", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "invite_expires_at"
    t.datetime "invite_sent_at"
    t.string "invite_token"
    t.string "invited_email"
    t.bigint "project_id", null: false
    t.datetime "reminder_sent_at"
    t.string "role", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["invite_token"], name: "index_project_members_on_invite_token", unique: true, where: "(invite_token IS NOT NULL)"
    t.index ["project_id", "user_id"], name: "index_project_members_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "project_notes", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "created_at"], name: "index_project_notes_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_project_notes_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.text "additional_entrepreneurs"
    t.text "architecte_adresse"
    t.decimal "architecte_devis_montant", precision: 10, scale: 2
    t.string "architecte_email"
    t.string "architecte_entreprise"
    t.string "architecte_nom"
    t.string "architecte_numero_ordre"
    t.string "architecte_prenom"
    t.text "architecte_specialites"
    t.string "architecte_telephone"
    t.string "bce_number"
    t.decimal "contractor_devis_montant", precision: 10, scale: 2
    t.string "coordinateur_securite_contact"
    t.string "coordinateur_securite_nom"
    t.text "corps_metiers"
    t.datetime "created_at", null: false
    t.date "date_audit"
    t.date "date_début"
    t.date "date_fin"
    t.text "description"
    t.string "entrepreneur_bce_statut"
    t.datetime "entrepreneur_bce_verifie_at"
    t.text "entrepreneur_principal_adresse"
    t.text "entrepreneur_principal_certifications"
    t.string "entrepreneur_principal_email"
    t.string "entrepreneur_principal_entreprise"
    t.string "entrepreneur_principal_nom"
    t.string "entrepreneur_principal_numero_tva"
    t.string "entrepreneur_principal_telephone"
    t.boolean "extension_works"
    t.boolean "facade_works"
    t.text "garanties_travaux"
    t.date "invoice_date"
    t.string "maitre_ouvrage_contact"
    t.string "maitre_ouvrage_nom"
    t.string "nom"
    t.string "numero_agrement_auditeur"
    t.string "numero_audit"
    t.boolean "parties_communes"
    t.string "permis_urbanisme_autorite"
    t.date "permis_urbanisme_date"
    t.jsonb "permis_urbanisme_historique", default: [], null: false
    t.text "permis_urbanisme_notes"
    t.string "permis_urbanisme_number"
    t.string "permis_urbanisme_statut"
    t.jsonb "phases_avancement", default: {}, null: false
    t.text "previous_subsidies"
    t.decimal "prix_audit", precision: 10, scale: 2
    t.string "project_type", default: "renovation"
    t.bigint "property_id", null: false
    t.boolean "reconstruction_demolition"
    t.string "statut"
    t.integer "surface_professionnelle"
    t.integer "surface_totale"
    t.boolean "toiture_modification"
    t.boolean "tva_reduit_6_pourcent"
    t.text "type_travaux"
    t.datetime "updated_at", null: false
    t.boolean "usage_professionnel"
    t.bigint "user_id", null: false
    t.datetime "vision_analysed_at"
    t.jsonb "vision_analysis"
    t.date "work_completion_date"
    t.index ["property_id"], name: "index_projects_on_property_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "adresse"
    t.integer "annee_construction"
    t.boolean "audit_energetique"
    t.string "autre_bien"
    t.boolean "bien_classe"
    t.string "certificat_peb_bruxelles"
    t.string "certificat_peb_flandre"
    t.string "certificat_peb_wallonie"
    t.string "chauffage_post_renovation_flandre"
    t.boolean "client_protege_flandre"
    t.string "code_postal"
    t.string "commune"
    t.datetime "created_at", null: false
    t.date "date_achat"
    t.date "date_classement"
    t.date "date_mise_en_vente"
    t.date "date_peb_apres_travaux"
    t.date "date_peb_avant_travaux"
    t.integer "date_raccordement_electrique"
    t.string "denomination_monument"
    t.boolean "domiciliation"
    t.boolean "domicilie_flandre"
    t.string "ean_flandre"
    t.text "elements_petit_patrimoine"
    t.boolean "facade_patrimoine"
    t.datetime "geocoded_at"
    t.integer "habitation_percentage"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "mode_chauffage_principal"
    t.string "mode_chauffage_wallonie"
    t.integer "nombre_lots_copropriete"
    t.boolean "nouvelle_construction"
    t.string "numero"
    t.string "numero_cadastre"
    t.string "numero_dossier_monument"
    t.string "numero_ean"
    t.string "occupation"
    t.string "parcelle_flandre"
    t.string "peb"
    t.boolean "petit_patrimoine"
    t.integer "pourcentage_propriete"
    t.boolean "primes_recues"
    t.decimal "prix_vente_estime", precision: 12, scale: 2
    t.string "profil_demandeur"
    t.string "reconstruit"
    t.string "region"
    t.string "rue"
    t.string "statut_patrimonial"
    t.string "statut_vente", default: "actif", null: false
    t.integer "surface_habitable"
    t.integer "surface_habitable_wallonie"
    t.integer "surface_totale"
    t.string "titre"
    t.string "type"
    t.string "type_bien_bruxelles"
    t.string "type_bien_flandre"
    t.string "type_bien_wallonie"
    t.string "type_demandeur"
    t.string "type_propriete"
    t.string "type_propriete_flandre"
    t.string "type_propriete_wallonie"
    t.datetime "updated_at", null: false
    t.string "usage"
    t.string "usage_flandre"
    t.bigint "user_id", null: false
    t.decimal "valeur_achat", precision: 10, scale: 2
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["statut_vente"], name: "index_properties_on_statut_vente"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "pv_receptions", force: :cascade do |t|
    t.text "absents"
    t.text "commentaire_architect"
    t.text "commentaire_entrepreneur"
    t.text "commentaire_owner"
    t.string "coordinateur_sps"
    t.datetime "created_at", null: false
    t.date "date_reception"
    t.string "email_architect"
    t.string "email_entrepreneur"
    t.string "email_owner"
    t.string "heure_reception"
    t.date "legal_archive_until"
    t.jsonb "lots_reception", default: []
    t.string "meteo"
    t.string "nom_architect"
    t.string "nom_entrepreneur"
    t.string "nom_owner"
    t.text "observations"
    t.text "presents"
    t.bigint "project_id", null: false
    t.text "reserves_snapshot"
    t.datetime "sent_architect_at"
    t.datetime "sent_entrepreneur_at"
    t.datetime "sent_owner_at"
    t.datetime "signed_architect_at"
    t.datetime "signed_entrepreneur_at"
    t.datetime "signed_owner_at"
    t.string "source"
    t.string "statut", default: "draft", null: false
    t.string "token_architect"
    t.string "token_entrepreneur"
    t.string "token_owner"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_pv_receptions_on_project_id", unique: true
    t.index ["token_architect"], name: "index_pv_receptions_on_token_architect", unique: true, where: "(token_architect IS NOT NULL)"
    t.index ["token_entrepreneur"], name: "index_pv_receptions_on_token_entrepreneur", unique: true, where: "(token_entrepreneur IS NOT NULL)"
    t.index ["token_owner"], name: "index_pv_receptions_on_token_owner", unique: true, where: "(token_owner IS NOT NULL)"
  end

  create_table "pv_visites", force: :cascade do |t|
    t.text "absents"
    t.bigint "auteur_id", null: false
    t.string "coordinateur_sps"
    t.datetime "created_at", null: false
    t.date "date_visite", null: false
    t.jsonb "decisions", default: [], null: false
    t.string "heure_visite"
    t.jsonb "lots", default: [], null: false
    t.string "meteo"
    t.integer "numero", default: 1, null: false
    t.text "observations"
    t.jsonb "points", default: [], null: false
    t.text "presents"
    t.date "prochaine_visite"
    t.string "prochaine_visite_heure"
    t.bigint "project_id", null: false
    t.string "statut", default: "draft", null: false
    t.string "token_entrepreneur"
    t.string "token_owner"
    t.datetime "updated_at", null: false
    t.index ["auteur_id"], name: "index_pv_visites_on_auteur_id"
    t.index ["project_id", "numero"], name: "index_pv_visites_on_project_id_and_numero", unique: true
    t.index ["project_id"], name: "index_pv_visites_on_project_id"
    t.index ["token_entrepreneur"], name: "index_pv_visites_on_token_entrepreneur", unique: true, where: "(token_entrepreneur IS NOT NULL)"
    t.index ["token_owner"], name: "index_pv_visites_on_token_owner", unique: true, where: "(token_owner IS NOT NULL)"
  end

  create_table "quote_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "options", default: {}
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.bigint "quote_id", null: false
    t.decimal "total_avg", precision: 10, scale: 2
    t.decimal "total_max", precision: 10, scale: 2
    t.decimal "total_min", precision: 10, scale: 2
    t.string "unit", null: false
    t.decimal "unit_price_avg", precision: 10, scale: 2
    t.decimal "unit_price_max", precision: 10, scale: 2
    t.decimal "unit_price_min", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.string "work_type_key", null: false
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_avg_days"
    t.integer "duration_max_days"
    t.integer "duration_min_days"
    t.bigint "property_id", null: false
    t.string "status", default: "draft", null: false
    t.decimal "total_avg", precision: 10, scale: 2
    t.decimal "total_max", precision: 10, scale: 2
    t.decimal "total_min", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["property_id"], name: "index_quotes_on_property_id"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "rent_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.bigint "lease_id", null: false
    t.text "notes"
    t.date "paid_date"
    t.string "payment_method"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_rent_payments_on_due_date"
    t.index ["lease_id"], name: "index_rent_payments_on_lease_id"
    t.index ["status"], name: "index_rent_payments_on_status"
  end

  create_table "request_progresses", force: :cascade do |t|
    t.text "commentaires_admin"
    t.boolean "completed"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "date_derniere_maj"
    t.date "date_soumission"
    t.string "document_extraction_status", default: "pending", comment: "Statut de l'extraction: pending, processing, completed, failed"
    t.boolean "document_recu", default: false
    t.datetime "email_processed_at", comment: "Date de traitement du dernier email reçu"
    t.string "email_suivi", null: false
    t.text "extracted_data", comment: "Données JSON extraites des documents reçus par email"
    t.string "form_name"
    t.string "form_type"
    t.decimal "montant_accorde", precision: 10, scale: 2
    t.decimal "montant_demande", precision: 10, scale: 2
    t.string "numero_dossier"
    t.integer "pourcentage"
    t.string "prime_accordee"
    t.bigint "prime_id"
    t.bigint "request_id", null: false
    t.string "status_administratif", default: "en_preparation"
    t.string "step"
    t.datetime "updated_at", null: false
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
    t.boolean "acceptation_conditions"
    t.string "adresse"
    t.string "annee_aer"
    t.string "categories_travaux"
    t.string "chauffage_post_renovation"
    t.string "code_postal"
    t.string "commune"
    t.string "composition_menage"
    t.string "compte_bancaire"
    t.datetime "confirmation_offre_at"
    t.boolean "confirmation_veracite"
    t.decimal "cout_estime", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "domicile"
    t.string "ean"
    t.boolean "eigenaar_bewoner"
    t.string "email"
    t.string "email_contact"
    t.jsonb "form_data", default: {}
    t.string "form_type"
    t.string "gezinssamenstelling"
    t.integer "inkomen_gezin"
    t.decimal "kostprijs_werken", precision: 10, scale: 2
    t.boolean "logement_principal"
    t.float "montant_total"
    t.decimal "montant_travaux", precision: 10, scale: 2
    t.string "nom"
    t.integer "nombre_personnes"
    t.string "parcelle"
    t.integer "personnes_charge"
    t.string "prenom"
    t.bigint "project_id"
    t.bigint "property_id"
    t.string "region"
    t.string "registre_national"
    t.integer "revenus_annuels"
    t.integer "revenus_menage"
    t.integer "revenus_reference"
    t.bigint "simulation_id"
    t.string "status"
    t.datetime "submitted_at"
    t.decimal "surface_travaux", precision: 10, scale: 2
    t.string "telephone"
    t.string "telephone_contact"
    t.string "template_version", default: "1.0"
    t.string "title"
    t.boolean "travaux_chauffage"
    t.boolean "travaux_complementaires"
    t.boolean "travaux_murs"
    t.boolean "travaux_sol"
    t.boolean "travaux_solaire"
    t.boolean "travaux_toiture"
    t.boolean "travaux_ventilation"
    t.boolean "travaux_vitrage"
    t.string "type_bien"
    t.string "type_demandeur"
    t.string "type_renovatie"
    t.string "type_travaux"
    t.datetime "updated_at", null: false
    t.string "usage"
    t.bigint "user_id", null: false
    t.datetime "validated_at"
    t.index ["form_data"], name: "index_requests_on_form_data", using: :gin
    t.index ["form_type"], name: "index_requests_on_form_type"
    t.index ["project_id"], name: "index_requests_on_project_id"
    t.index ["property_id"], name: "index_requests_on_property_id"
    t.index ["simulation_id"], name: "index_requests_on_simulation_id"
    t.index ["user_id"], name: "index_requests_on_user_id"
  end

  create_table "reserves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_constat"
    t.date "date_limite"
    t.text "description"
    t.string "etage"
    t.text "notes"
    t.float "pin_x"
    t.float "pin_y"
    t.bigint "plan_document_id"
    t.bigint "project_id", null: false
    t.string "responsable"
    t.string "statut", default: "ouverte", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_document_id"], name: "index_reserves_on_plan_document_id"
    t.index ["project_id", "statut"], name: "index_reserves_on_project_id_and_statut"
    t.index ["project_id"], name: "index_reserves_on_project_id"
  end

  create_table "rib_donnees", force: :cascade do |t|
    t.string "bic"
    t.decimal "confiance_ocr", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.jsonb "donnees_extraites", default: {}
    t.boolean "extraction_complete", default: false, null: false
    t.text "iban"
    t.string "nom_banque"
    t.text "nom_titulaire"
    t.text "texte_ocr_brut"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "valide_manuellement", default: false, null: false
    t.index ["document_id"], name: "index_rib_donnees_on_document_id"
    t.index ["user_id"], name: "index_rib_donnees_on_user_id"
  end

  create_table "simulations", force: :cascade do |t|
    t.string "category"
    t.text "category_description"
    t.datetime "created_at", null: false
    t.boolean "eligible"
    t.text "ineligibility_reason"
    t.text "parameters"
    t.bigint "project_id"
    t.bigint "property_id", null: false
    t.string "regime", default: "primes_cash"
    t.string "region"
    t.string "source"
    t.string "titre"
    t.decimal "total_simule"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_simulations_on_project_id"
    t.index ["property_id"], name: "index_simulations_on_property_id"
    t.index ["regime"], name: "index_simulations_on_regime"
    t.index ["user_id"], name: "index_simulations_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.string "status"
    t.string "stripe_subscription_id"
    t.string "tier"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "support_messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "is_admin_reply"
    t.bigint "support_ticket_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["support_ticket_id"], name: "index_support_messages_on_support_ticket_id"
    t.index ["user_id"], name: "index_support_messages_on_user_id"
  end

  create_table "support_tickets", force: :cascade do |t|
    t.string "category", default: "general", null: false
    t.datetime "created_at", null: false
    t.string "priority"
    t.datetime "responded_at"
    t.string "status"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_support_tickets_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.text "national_number_ciphertext"
    t.text "notes"
    t.string "phone"
    t.bigint "property_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["property_id"], name: "index_tenants_on_property_id"
    t.index ["user_id"], name: "index_tenants_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "annee_revenus_conjoint"
    t.string "annee_revenus_demandeur"
    t.string "city"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "contacted_at"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.boolean "femme_enceinte"
    t.string "first_name"
    t.text "iban"
    t.string "last_name"
    t.datetime "last_project_alert_at"
    t.datetime "locked_at"
    t.text "national_number"
    t.string "nom"
    t.string "nom_cabinet"
    t.integer "nombre_enfants"
    t.datetime "nps_prompted_at"
    t.string "num_bce"
    t.string "number"
    t.datetime "nurturing_n14_sent_at"
    t.datetime "nurturing_n30_sent_at"
    t.datetime "nurturing_n60_sent_at"
    t.datetime "onboarding_completed_at"
    t.datetime "onboarding_j1_sent_at"
    t.datetime "onboarding_j3_sent_at"
    t.datetime "onboarding_j7_sent_at"
    t.integer "personnes_60_ans_et_plus"
    t.string "phone"
    t.string "postal_code"
    t.string "preferred_locale", default: "fr"
    t.boolean "primes_services_client", default: false, null: false
    t.string "professional_type"
    t.string "protected_client"
    t.string "referral_token"
    t.string "region"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "revenu_conjoint"
    t.integer "revenu_demandeur"
    t.integer "role", default: 0, null: false
    t.string "situation_familiale"
    t.string "street"
    t.string "stripe_customer_id"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.integer "user_profile", default: 0, null: false
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
    t.boolean "active", default: true, null: false
    t.text "admin_notes"
    t.text "contenu"
    t.datetime "created_at", null: false
    t.string "region"
    t.string "source"
    t.date "source_date"
    t.text "themes"
    t.string "titre"
    t.datetime "updated_at", null: false
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
  add_foreign_key "etat_avancement_lignes", "etats_avancement", column: "etat_avancement_id"
  add_foreign_key "etats_avancement", "devis_donnees"
  add_foreign_key "etats_avancement", "projects"
  add_foreign_key "etats_avancement", "users", column: "created_by_id"
  add_foreign_key "factures", "documents"
  add_foreign_key "factures", "projects"
  add_foreign_key "factures", "properties"
  add_foreign_key "leases", "properties"
  add_foreign_key "leases", "tenants"
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
  add_foreign_key "pret_wallonie_dossiers", "projects"
  add_foreign_key "pret_wallonie_dossiers", "simulations"
  add_foreign_key "pret_wallonie_dossiers", "users"
  add_foreign_key "prime_submissions", "properties"
  add_foreign_key "prime_submissions", "users"
  add_foreign_key "primes", "categories"
  add_foreign_key "project_checklist_items", "checklist_items"
  add_foreign_key "project_checklist_items", "project_checklists"
  add_foreign_key "project_checklists", "checklist_templates"
  add_foreign_key "project_checklists", "projects"
  add_foreign_key "project_members", "projects"
  add_foreign_key "project_members", "users"
  add_foreign_key "project_notes", "projects"
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
  add_foreign_key "reserves", "projects"
  add_foreign_key "rib_donnees", "documents"
  add_foreign_key "rib_donnees", "users"
  add_foreign_key "simulations", "projects"
  add_foreign_key "simulations", "properties"
  add_foreign_key "simulations", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subscriptions", "users"
  add_foreign_key "support_messages", "support_tickets"
  add_foreign_key "support_messages", "users"
  add_foreign_key "support_tickets", "users"
  add_foreign_key "tenants", "properties"
  add_foreign_key "tenants", "users"
end
