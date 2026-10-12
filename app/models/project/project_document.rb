# V2 — Lot 1 : base documentaire commune du chantier (cahier des charges §4-6).
# Distinct du modèle Document V1 (app/models/documents/document.rb), laissé
# intact — voir le commentaire de
# db/migrate/20261012100100_create_project_documents_system.rb pour pourquoi.
class ProjectDocument < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true
  belongs_to :phase, optional: true
  belongs_to :uploaded_by, class_name: "User"
  belongs_to :current_version, class_name: "ProjectDocumentVersion", optional: true

  # Doit être déclaré AVANT `has_many :versions, dependent: :destroy` : les
  # callbacks before_destroy s'exécutent dans l'ordre de déclaration, et
  # current_version_id (FK vers project_document_versions) doit être mis à
  # nil avant que Rails ne tente de détruire les versions, sinon
  # PG::ForeignKeyViolation (le document référence encore la version qu'on
  # essaie de supprimer).
  before_destroy :detach_current_version

  has_many :versions, class_name: "ProjectDocumentVersion", dependent: :destroy
  has_many :comments, class_name: "ProjectDocumentComment", dependent: :destroy
  # delete_all, pas destroy : ProjectDocumentReview est append-only (voir son
  # before_destroy) — dependent: :destroy appellerait #destroy sur chaque
  # ligne et lèverait ActiveRecord::ReadOnlyRecord. delete_all fait un DELETE
  # SQL direct, sans passer par les callbacks du modèle.
  has_many :reviews, class_name: "ProjectDocumentReview", dependent: :delete_all
  has_many :shares, class_name: "ProjectDocumentShare", dependent: :destroy
  has_many :shared_users, through: :shares, source: :user

  accepts_nested_attributes_for :versions

  # Liste volontairement restreinte pour le MVP du Lot 1 — le catalogue complet
  # de types (cahier des charges §5.B : devis, plan, facture, permis,
  # attestation, photo, PV, garantie...) arrive avec l'ingestion IA du Lot 2,
  # qui a besoin de classer automatiquement bien plus de types que ceux
  # qu'un formulaire manuel doit proposer aujourd'hui.
  DOCUMENT_TYPES = %w[devis facture plan permis attestation photo pv garantie autre].freeze

  enum :visibility, { private_doc: "private", lot: "lot", all: "all", custom: "custom" }, default: "all", prefix: :visibility
  enum :status, { brouillon: "brouillon", soumis: "soumis", valide: "valide", refuse: "refuse", a_corriger: "a_corriger" }, default: "brouillon"

  validates :title, presence: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validate :lot_belongs_to_project
  validate :phase_belongs_to_project

  # V2 — Lot 2 : proposition de classification IA (cahier des charges §8 :
  # "proposition de rattachement, validation en un clic"). Stockée sur la
  # version courante par ProjectDocumentIngestionJob, jamais appliquée
  # automatiquement — voir #apply_ai_suggestion!.
  def ai_suggestion
    current_version&.extracted_metadata&.slice(
      "ai_suggested_document_type", "ai_suggested_lot_key", "ai_suggested_phase_key",
      "ai_suggested_montant_ttc", "ai_confidence"
    )&.presence
  end

  # Confirmation humaine explicite — appelé uniquement depuis un clic
  # contrôleur (ProjectDocumentsController#accept_suggestion), jamais par
  # l'ingestion elle-même.
  def apply_ai_suggestion!
    suggestion = ai_suggestion
    return false if suggestion.blank?

    update!(
      document_type: suggestion["ai_suggested_document_type"].presence || document_type,
      lot: suggestion["ai_suggested_lot_key"].present? ? project.lots.find_by(key: suggestion["ai_suggested_lot_key"]) : lot,
      phase: suggestion["ai_suggested_phase_key"].present? ? project.phases.find_by(key: suggestion["ai_suggested_phase_key"]) : phase
    )
  end

  private

  def detach_current_version
    update_column(:current_version_id, nil) if current_version_id.present?
  end

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end

  def phase_belongs_to_project
    return if phase.blank?
    errors.add(:phase, "n'appartient pas à ce chantier") if phase.project_id != project_id
  end
end
