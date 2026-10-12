# V2 — Lot 1 : DocumentReview (cahier des charges §4) — historique des avis
# (validé/refusé/à corriger, par qui, quand). Append-only comme AuditEvent :
# un avis de revue est un fait, jamais corrigé après coup (une nouvelle revue
# est créée si l'avis change).
class ProjectDocumentReview < ApplicationRecord
  belongs_to :project_document
  belongs_to :project_document_version, optional: true
  belongs_to :reviewer, class_name: "User"

  STATUSES = %w[valide refuse a_corriger].freeze

  validates :status, inclusion: { in: STATUSES }

  after_create :apply_status_to_document

  before_update { raise ActiveRecord::ReadOnlyRecord, "ProjectDocumentReview est append-only : aucune modification après création" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "ProjectDocumentReview est append-only : aucune suppression" }

  private

  def apply_status_to_document
    project_document.update_column(:status, status)
  end
end
