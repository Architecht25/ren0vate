# V2 — Lot 1 : base documentaire versionnée (cahier des charges §4-6).
#
# Nommée "project_documents"/"ProjectDocument", PAS "documents"/"Document" —
# la table et le modèle Document V1 existent déjà et restent intacts
# (voir app/models/documents/document.rb). Les réutiliser aurait été
# dangereux : active_storage_attachments.record_type stocke "Document" en
# dur pour chaque fichier déjà uploadé en V1 (voir le commentaire dans
# config/initializers/zeitwerk.rb sur ce risque précis — un renommage de
# classe orpheline les fichiers déjà en production). Document V1 et ses
# ~15 services OCR/Claude dépendants sont laissés tels quels sur cette
# branche ; ils seront rebranchés sur ce nouveau système (ou retirés) au
# Lot 2, au moment de la bascule de stockage vers Scaleway qui touche de
# toute façon ces attachments.
#
# Deux migrations car project_documents.current_version_id référence
# project_document_versions, qui référence project_documents — dépendance
# circulaire résolue en ajoutant la colonne dans une seconde migration.
class CreateProjectDocumentsSystem < ActiveRecord::Migration[8.1]
  def change
    create_table :project_documents do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true
      t.references :phase, null: true, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.string :document_type, null: false
      t.string :visibility, null: false, default: "all"
      t.string :status, null: false, default: "brouillon"

      t.timestamps
    end

    create_table :project_document_versions do |t|
      t.references :project_document, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.integer :version_number, null: false
      t.string :sha256
      t.string :file_name
      t.string :content_type
      t.bigint :byte_size
      t.text :ocr_text
      t.jsonb :extracted_metadata, null: false, default: {}

      t.timestamps
    end
    add_index :project_document_versions, [:project_document_id, :version_number], unique: true

    create_table :project_document_comments do |t|
      t.references :project_document, null: false, foreign_key: true
      t.references :project_document_version, null: true, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.jsonb :anchor, null: false, default: {}

      t.timestamps
    end

    create_table :project_document_reviews do |t|
      t.references :project_document, null: false, foreign_key: true
      t.references :project_document_version, null: true, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false
      t.text :comment

      t.datetime :created_at, null: false
      # Pas d'updated_at : un avis de revue est un fait historique, jamais modifié (voir AuditEvent).
    end

    create_table :project_document_shares do |t|
      t.references :project_document, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :project_document_shares, [:project_document_id, :user_id], unique: true, name: "index_pd_shares_on_document_and_user"
  end
end
