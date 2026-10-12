# V2 — Lot 2 : devis structuré (cahier des charges §4 : "Quote (devis
# structuré : entrepreneur, lot, postes, total HT/TVA/TTC, statut) et
# QuoteLine"). Nommé ProjectQuote/ProjectQuoteLine — "Quote" est déjà pris
# par Devis::Quote (V1, app/models/devis/quote.rb), un modèle quasi mort
# (3 usages, scopé par bien et pas par chantier, sans aucun champ de
# montant) laissé intact plutôt que réutilisé ou supprimé, conformément à
# la même prudence que pour Document (voir docs/AUDIT_V1.md §3.4).
class CreateProjectQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :project_quotes do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true
      t.references :project_document, null: true, foreign_key: true # devis scanné d'origine, si déposé via la base documentaire
      t.references :submitted_by, null: true, foreign_key: { to_table: :users } # entrepreneur ayant déposé le devis, si membre du chantier

      t.string :entreprise_nom
      t.string :status, null: false, default: "brouillon"
      t.decimal :montant_ht, precision: 10, scale: 2
      t.decimal :montant_tva, precision: 10, scale: 2
      t.decimal :montant_ttc, precision: 10, scale: 2

      t.timestamps
    end

    create_table :project_quote_lines do |t|
      t.references :project_quote, null: false, foreign_key: true

      t.string :description, null: false
      t.decimal :quantite, precision: 10, scale: 2, null: false, default: 1
      t.string :unite
      t.decimal :prix_unitaire_ht, precision: 10, scale: 2, null: false
      t.decimal :montant_ht, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
