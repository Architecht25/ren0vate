class CreateEtatsAvancement < ActiveRecord::Migration[8.0]
  def change
    create_table :etats_avancement do |t|
      t.references :project,           null: false, foreign_key: true
      t.references :created_by,        null: false, foreign_key: { to_table: :users }
      t.references :devis_donnee,       null: true,  foreign_key: true  # source OCR optionnelle

      t.integer    :numero,             null: false, default: 1, comment: "État n°1, n°2…"
      t.string     :source_type,        null: false, default: 'manuel',
                   comment: "devis_entrepreneur | metre_architecte | manuel"
      t.string     :statut,             null: false, default: 'brouillon',
                   comment: "brouillon | soumis | approuve | rejete"
      t.date       :date_emission
      t.date       :periode_debut,      comment: "Début de la période couverte par cet état"
      t.date       :periode_fin,        comment: "Fin de la période couverte"
      t.text       :commentaire_entrepreneur
      t.text       :commentaire_architecte
      t.decimal    :montant_total_marche,  precision: 12, scale: 2,
                   comment: "Total du marché (contrat)"
      t.decimal    :montant_cumule_precedent, precision: 12, scale: 2, default: 0,
                   comment: "Cumul approuvé des états précédents"
      t.decimal    :montant_reclame_periode, precision: 12, scale: 2, default: 0,
                   comment: "Montant réclamé sur cette période (calculé)"
      t.decimal    :montant_cumule_actuel,   precision: 12, scale: 2, default: 0,
                   comment: "Cumul actuel (précédent + période)"
      t.boolean    :genere_par_ia,      default: false,
                   comment: "Architecture initiale générée par IA"
      t.text       :resume_ia,          comment: "Résumé textuel généré par Claude"
      t.datetime   :soumis_at
      t.datetime   :approuve_at
      t.datetime   :rejete_at

      t.timestamps
    end

    add_index :etats_avancement, [:project_id, :numero], unique: true
    add_index :etats_avancement, :statut

    create_table :etat_avancement_lignes do |t|
      t.references :etat_avancement,   null: false, foreign_key: { to_table: :etats_avancement }

      t.string     :thematique_code,   null: false,
                   comment: "Code de la thématique principale (ex: toiture, electricite)"
      t.string     :thematique_label,  null: false,
                   comment: "Libellé affiché de la thématique"
      t.string     :sous_secteur,
                   comment: "Sous-secteur (ex: charpente, couverture)"
      t.string     :reference,         comment: "Référence poste contrat (1.1, 2.3…)"
      t.text       :designation,       null: false, comment: "Description du poste"
      t.string     :unite,             default: 'forfait'
      t.decimal    :quantite,          precision: 10, scale: 3
      t.decimal    :prix_unitaire,     precision: 10, scale: 2
      t.decimal    :montant_marche,    precision: 12, scale: 2,
                   comment: "Montant contractuel = qté × PU"
      t.integer    :pct_cumule_precedent, default: 0,
                   comment: "% réalisé dans les états précédents"
      t.integer    :pct_cumule_actuel,    default: 0,
                   comment: "% réalisé déclaré dans cet état (saisi par entrepreneur)"
      t.decimal    :montant_reclame,   precision: 12, scale: 2,
                   comment: "Montant réclamé = montant_marche × Δ% / 100"
      t.integer    :position,          default: 0, comment: "Ordre d'affichage"
      t.boolean    :ia_suggere,        default: false,
                   comment: "Ligne proposée par l'IA (non encore validée)"
      t.string     :ia_confiance,      comment: "haute | moyenne | faible"

      t.timestamps
    end

    add_index :etat_avancement_lignes, [:etat_avancement_id, :position]
    add_index :etat_avancement_lignes, :thematique_code
  end
end
