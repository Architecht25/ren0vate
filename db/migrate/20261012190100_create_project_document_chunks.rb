# V2 — Lot 5 : chunks de texte + embeddings pour la recherche sémantique
# (cahier des charges §4 : assistant conversationnel sur dossier, §8.7).
#
# Dimension du vecteur (1024) calée sur le modèle Voyage AI "voyage-3"
# (choisi avec Robin le 12/10/2026 — Anthropic ne fournit pas d'API
# d'embeddings, Voyage AI est son partenaire recommandé). Vérifiée par un
# appel réel le 12/10/2026 une fois la clé VOYAGE_API_KEY fournie — voir
# docs/QUESTIONS_OUVERTES.md Q15.
class CreateProjectDocumentChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :project_document_chunks do |t|
      t.references :project_document_version, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true # dénormalisé — filtrer par droits avant la recherche vectorielle sans jointure

      t.text :content, null: false
      t.integer :chunk_index, null: false
      t.vector :embedding, limit: 1024

      t.timestamps
    end

    add_index :project_document_chunks, [:project_document_version_id, :chunk_index], unique: true, name: "index_chunks_on_version_and_index"
  end
end
