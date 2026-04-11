class CreateAuditEnergDonnees < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_energ_donnees do |t|
      t.references :document,  null: true,  foreign_key: true
      t.references :user,      null: false, foreign_key: true
      t.references :property,  null: true,  foreign_key: true
      t.references :project,   null: true,  foreign_key: { on_delete: :nullify }

      # ── Identification (page 2) ─────────────────────────────────────────────
      t.string  :numero_audit                      # A20230607001678/01
      t.date    :date_enregistrement               # 07.06.2023
      t.string  :numero_pae                        # PAE2-P3-00537
      t.string  :denomination_auditeur             # Magibase SRL
      t.text    :adresse_auditeur                  # Allée des Renards, 25, 5170 Profondeville

      # ── Labels énergétiques ─────────────────────────────────────────────────
      t.string  :label_initial                     # F (situation initiale modifiée)
      t.string  :label_final                       # A+ (dernier bouquet)

      # ── Recommandations — bouquets pages 18-21 ──────────────────────────────
      # [{bouquet, reference, denomination, recommandation,
      #   label_avant, label_apres,
      #   gain_reel_kwh, economie_euro_an, cout_estime_euro,
      #   subsides_euro, temps_retour_ans}]
      t.jsonb   :recommandations_json, default: []

      # ── Bilan global — scénario complet (page 21) ────────────────────────────
      # {economie_an, cout_total, subsides_total, temps_retour}
      t.jsonb   :bilan_json, default: {}

      # ── Qualité OCR ─────────────────────────────────────────────────────────
      t.decimal :confiance_ocr,      precision: 5, scale: 2
      t.boolean :extraction_complete, default: false, null: false
      t.boolean :valide_manuellement, default: false, null: false
      t.text    :texte_ocr_brut
      t.jsonb   :donnees_extraites,  default: {}

      t.timestamps
    end

    add_index :audit_energ_donnees, :numero_audit
    add_index :audit_energ_donnees, :recommandations_json, using: :gin
  end
end
