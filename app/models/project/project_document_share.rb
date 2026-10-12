# V2 — Lot 1 : liste d'accès explicite pour un document en visibilité
# "custom" (cahier des charges §4 : "partage ciblé"). Sans effet pour les
# autres visibilités (private/lot/all) — voir ProjectDocumentPolicy.
class ProjectDocumentShare < ApplicationRecord
  belongs_to :project_document
  belongs_to :user

  validates :user_id, uniqueness: { scope: :project_document_id }
end
