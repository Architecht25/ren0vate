# V2 — Lot 5 : segment de texte + embedding, unité de recherche de
# l'assistant sur dossier (cahier des charges §4, §8.7). project_id est
# dénormalisé depuis project_document_version pour permettre de filtrer
# par droits (quels project_document_id l'utilisateur peut voir) AVANT la
# recherche de similarité vectorielle, jamais après — règle de sécurité
# non négociable du cahier des charges §8 : "les droits sont appliqués
# avant la recherche vectorielle... jamais après".
class ProjectDocumentChunk < ApplicationRecord
  belongs_to :project_document_version
  belongs_to :project

  has_neighbors :embedding

  validates :content, presence: true
  validates :chunk_index, presence: true

  delegate :project_document, to: :project_document_version
end
