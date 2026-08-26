class AddClaudeExtractionToAuditEnergDonnees < ActiveRecord::Migration[8.0]
  def change
    change_table :audit_energ_donnees, bulk: true do |t|
      # ── Validité (page 1 : "Valable jusqu'au") ───────────────────────────────
      t.date    :date_modification
      t.date    :valable_jusquau

      # ── Descriptif du bien (page 4) ──────────────────────────────────────────
      t.text    :adresse_bien
      t.string  :type_logement
      t.string  :annee_construction
      t.decimal :volume_protege_m3,           precision: 8, scale: 2
      t.decimal :surface_deperdition_m2,      precision: 8, scale: 2
      t.decimal :surface_plancher_chauffe_m2, precision: 8, scale: 2

      # ── Performance détaillée — initiale / initiale modifiée / après travaux (page 13) ──
      # { "initiale" => {niveau_k, label_besoins_chauffage, label_systeme_chauffage,
      #     label_systeme_ecs, energie_finale_kwh, energie_primaire_kwh,
      #     pourcentage_renouvelable, emissions_co2_t},
      #   "initiale_modifiee" => {...} | nil, "apres_travaux" => {...} }
      t.jsonb   :performance_json, default: {}, null: false

      # ── Projection certificat PEB — trajectoire Label A 2050 (page 45) ───────
      # { epw_initial, epw_apres, besoins_chaleur: {initial, apres},
      #   performance_chauffage: {...}, performance_ecs: {...},
      #   ventilation: {...}, renouvelables: {...} }
      t.jsonb   :peb_projection_json, default: {}, null: false

      # ── Feuille de route par étapes (page 1) ──────────────────────────────────
      # [{numero, label_cible, gain_pct_an, cout_cumule_euro, primes_cumule_euro, bouquets: []}]
      t.jsonb   :etapes_json, default: [], null: false

      # ── Alertes non-énergétiques / sécurité (pages 9, 17, 19, 39-42) ──────────
      # [{categorie, conforme, description}]
      t.jsonb   :alertes_json, default: [], null: false

      # ── Bilan financier — scénario complet (pages 22-25 / 44) ─────────────────
      t.decimal :cout_total_scenario,        precision: 10, scale: 2
      t.decimal :subsides_total_scenario,    precision: 10, scale: 2
      t.decimal :economie_annuelle_scenario, precision: 10, scale: 2
      t.string  :temps_retour_scenario

      # ── Traçabilité de la méthode d'extraction ────────────────────────────────
      t.string  :source_extraction, default: 'ocr', null: false # 'claude' | 'ocr_fallback' | 'ocr'
    end
  end
end
